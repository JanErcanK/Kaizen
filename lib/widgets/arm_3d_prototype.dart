import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

import '../services/progress_store.dart';
import '../theme/app_colors.dart';

class _ArmMuscleInfo {
  const _ArmMuscleInfo(this.name, this.function, this.exercises);

  final String name;
  final String function;
  final String exercises;
}

const _muscleInfo = <String, _ArmMuscleInfo>{
  'biceps_brachii': _ArmMuscleInfo(
    'Bizeps',
    'Beugt den Ellenbogen und dreht den Unterarm nach außen.',
    'Curls, Chin-ups, Rudern',
  ),
  'brachialis': _ArmMuscleInfo(
    'Armbeuger (Brachialis)',
    'Kräftiger Beuger des Ellenbogengelenks.',
    'Hammer Curls, Reverse Curls',
  ),
  'triceps_brachii': _ArmMuscleInfo(
    'Trizeps',
    'Streckt den Ellenbogen und stabilisiert den Oberarm.',
    'Dips, Liegestütze, Trizepsdrücken',
  ),
  'brachioradialis': _ArmMuscleInfo(
    'Oberarmspeichenmuskel',
    'Beugt den Ellenbogen besonders in neutraler Griffposition.',
    'Hammer Curls, Klimmzüge im Neutralgriff',
  ),
  'flexor_carpi_radialis': _ArmMuscleInfo(
    'Radialer Handbeuger',
    'Beugt das Handgelenk und führt es zur Daumenseite.',
    'Wrist Curls, Grifftraining',
  ),
  'flexor_digitorum_superficialis': _ArmMuscleInfo(
    'Oberflächlicher Fingerbeuger',
    'Beugt Finger und Handgelenk und unterstützt die Griffkraft.',
    'Farmer Walks, Dead Hangs, Wrist Curls',
  ),
  'pronator_teres': _ArmMuscleInfo(
    'Runder Einwärtsdreher',
    'Dreht den Unterarm nach innen und unterstützt die Ellenbogenbeugung.',
    'Unterarm-Pronation mit Band oder Kabel',
  ),
  'extensor_digitorum': _ArmMuscleInfo(
    'Fingerstrecker',
    'Streckt Finger und unterstützt die Streckung des Handgelenks.',
    'Finger Extensions, Reverse Wrist Curls',
  ),
  'extensor_carpi_ulnaris': _ArmMuscleInfo(
    'Ulnarer Handstrecker',
    'Streckt das Handgelenk und führt es zur Kleinfingerseite.',
    'Reverse Wrist Curls, Handgelenk-Abduktion',
  ),
};

/// Keeps the native WebView and the parsed 3D scene alive while the compact
/// body map is exchanged for the fullscreen overlay.
final _arm3DSession = _Arm3DSession();

class _Arm3DSession extends ChangeNotifier {
  final WebviewController controller = WebviewController();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void>? _initialization;
  bool webViewReady = false;
  bool modelLoaded = false;
  bool expanded = false;
  String? error;
  _ArmMuscleInfo? selectedMuscle;

  Future<void> ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      await controller.initialize();
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await controller.setBackgroundColor(AppColors.bodyMapBackground);

      _subscriptions.add(controller.webMessage.listen(_handleWebMessage));
      _subscriptions.add(
        controller.onLoadError.listen((status) {
          error = 'WebView-Ladefehler: $status';
          notifyListeners();
        }),
      );

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(_serve(server));

      final theme = ProgressStore.useLightTheme ? 'light' : 'dark';
      await controller.loadUrl('http://127.0.0.1:${server.port}/?theme=$theme');
      debugPrint('Arm3D: WebView started on local port ${server.port}');
      webViewReady = true;
      _syncExpandedState();
      notifyListeners();
    } catch (caughtError) {
      debugPrint('Arm3D: initialization failed: $caughtError');
      error = '3D-Ansicht konnte nicht starten: $caughtError';
      notifyListeners();
    }
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      try {
        final path = request.uri.path;
        final asset = switch (path) {
          '/' || '/index.html' => 'assets/3d_viewer/index.html',
          '/babylon.js' => 'assets/3d_viewer/babylon.js',
          '/babylonjs.loaders.min.js' =>
            'assets/3d_viewer/babylonjs.loaders.min.js',
          '/model.glb' => 'assets/models/detaillierter_arm_und_schulter_3d.glb',
          _ => null,
        };
        if (asset == null) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        final data = await rootBundle.load(asset);
        request.response.headers.set('Access-Control-Allow-Origin', '*');
        request.response.headers.contentType = switch (path) {
          '/' || '/index.html' => ContentType.html,
          '/model.glb' => ContentType('model', 'gltf-binary'),
          _ => ContentType('application', 'javascript', charset: 'utf-8'),
        };
        request.response.add(data.buffer.asUint8List());
        await request.response.close();
      } catch (_) {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
    }
  }

  void _handleWebMessage(dynamic message) {
    if (message is! Map) return;
    final type = message['type'];
    if (type == 'loaded') {
      debugPrint(
        'Arm3D: model loaded (${message['meshes']}) '
        'bounds=${message['diameter']} radius=${message['radius']} '
        'near=${message['minZ']}',
      );
      modelLoaded = true;
      error = null;
      _syncExpandedState();
      notifyListeners();
      return;
    }
    if (type == 'error') {
      debugPrint('Arm3D: model error: ${message['message']}');
      error = '3D-Modellfehler: ${message['message']}';
      notifyListeners();
      return;
    }
    if (type != 'selected') return;

    final meshName = '${message['name']}'.toLowerCase();
    for (final entry in _muscleInfo.entries) {
      if (meshName.contains(entry.key)) {
        selectedMuscle = entry.value;
        notifyListeners();
        return;
      }
    }
  }

  void setExpanded(bool value) {
    expanded = value;
    _syncExpandedState();
  }

  void _syncExpandedState() {
    if (!webViewReady || !modelLoaded) return;
    unawaited(
      controller.executeScript('window.setViewerExpanded?.($expanded);'),
    );
  }
}

/// Temporary Windows proof of concept for displaying and selecting GLB meshes.
class Arm3DPrototype extends StatefulWidget {
  const Arm3DPrototype({super.key, required this.expanded, this.onExpandTap});

  final bool expanded;
  final VoidCallback? onExpandTap;

  @override
  State<Arm3DPrototype> createState() => _Arm3DPrototypeState();
}

class _Arm3DPrototypeState extends State<Arm3DPrototype> {
  @override
  void initState() {
    super.initState();
    _arm3DSession.setExpanded(widget.expanded);
    _arm3DSession.addListener(_onSessionChanged);
    unawaited(_arm3DSession.ensureInitialized());
  }

  @override
  void didUpdateWidget(covariant Arm3DPrototype oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _arm3DSession.setExpanded(widget.expanded);
    }
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _arm3DSession.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = !widget.expanded;
    return ColoredBox(
      color: AppColors.bodyMapBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_arm3DSession.webViewReady)
            Webview(
              _arm3DSession.controller,
              permissionRequested: (_, _, _) async =>
                  WebviewPermissionDecision.deny,
            ),
          if (!_arm3DSession.modelLoaded && _arm3DSession.error == null)
            Positioned.fill(
              child: Image.asset(
                'assets/models/detaillierter_arm_und_schulter_3d_preview.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          if (_arm3DSession.error case final error?)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          if (compact)
            Positioned.fill(
              child: Tooltip(
                message: '3D-Ansicht öffnen',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onExpandTap,
                ),
              ),
            )
          else ...[
            if (_arm3DSession.selectedMuscle case final muscle?)
              Positioned(
                left: 232,
                right: 78,
                bottom: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.48),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          muscle.name,
                          style: TextStyle(
                            color: AppColors.accentText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          muscle.function,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Übungen: ${muscle.exercises}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
