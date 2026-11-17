import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/route_activity.dart';
import '../models/social_models.dart';
import '../services/progress_store.dart';
import '../services/run_snapshot_service.dart';
import '../services/social/live_run_publisher.dart';
import '../services/social/social_service.dart';
import '../theme/app_colors.dart';
import '../theme/green_screen_style.dart';
import 'share_with_friends_sheet.dart';

class RunSnapshotPreview extends StatefulWidget {
  const RunSnapshotPreview({
    super.key,
    required this.route,
    this.mapTiles = false,
  });
  final Map<String, dynamic> route;
  final bool mapTiles;

  @override
  State<RunSnapshotPreview> createState() => _RunSnapshotPreviewState();
}

class _RunSnapshotPreviewState extends State<RunSnapshotPreview> {
  Future<Uint8List>? _bytes;
  String? _language;

  Future<Uint8List> _load(bool german) async {
    final id = widget.route['snapshotId'];
    if (id is String) {
      try {
        final file = RunSnapshotService.file(id);
        if (await file.exists()) return await file.readAsBytes();
      } catch (_) {
        /* Rebuild images missing after a device restore. */
      }
    }
    return RunSnapshotService.render(
      widget.route,
      german: german,
      mapTiles: widget.mapTiles,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language != language) {
      _language = language;
      _bytes = _load(language == 'de');
    }
  }

  @override
  void didUpdateWidget(RunSnapshotPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route != widget.route) _bytes = _load(_language == 'de');
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: RunSnapshotService.width / RunSnapshotService.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, state) {
          if (state.hasData) {
            return GestureDetector(
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog.fullscreen(
                  child: Scaffold(
                    appBar: AppBar(
                      leading: CloseButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    body: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: Image.memory(state.data!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              child: Image.memory(
                state.data!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            );
          }
          if (state.hasError) {
            return const Center(child: Icon(Icons.broken_image_outlined));
          }
          return const Center(
            child: CircularProgressIndicator(color: GreenScreenStyle.accent),
          );
        },
      ),
    ),
  );
}

Future<void> showRunShareSheet({
  required BuildContext context,
  required Map<String, dynamic> route,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.card,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(
        context,
      ).colorScheme.copyWith(primary: GreenScreenStyle.accent),
    ),
    child: _RunShareSheet(route: route),
  ),
);

class _RunShareSheet extends StatefulWidget {
  const _RunShareSheet({required this.route});
  final Map<String, dynamic> route;
  @override
  State<_RunShareSheet> createState() => _RunShareSheetState();
}

class _RunShareSheetState extends State<_RunShareSheet> {
  late RouteActivityType _type = RouteActivity.fromJson(
    widget.route['activity'] as Map? ?? const {},
  ).type;
  bool _busy = false;
  String? _error;
  late Map<String, dynamic> _preview = Map<String, dynamic>.from(widget.route);
  bool get _german => Localizations.localeOf(context).languageCode == 'de';

  Map<String, dynamic> get _payload {
    final points = (widget.route['points'] as List)
        .map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
        .toList();
    return {
      'name': widget.route['name'] ?? 'Route',
      'points': boundedRunPoints(points, 1000),
      'waypoints': [points.first, points.last],
      'distanceMeters': widget.route['distanceMeters'] ?? 0,
      'ascentMeters': widget.route['ascentMeters'] ?? 0,
      'descentMeters': widget.route['descentMeters'] ?? 0,
      'steps': const <Map<String, dynamic>>[],
      'activity': {
        ...RouteActivity.fromJson(
          widget.route['activity'] as Map? ?? const {},
        ).toJson(),
        'type': _type.name,
      },
    };
  }

  Future<void> _send(String destination) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = _payload;
      if (destination == 'friends') {
        await showShareWithFriendsSheet(
          context: context,
          type: ShareContentType.runningRoute,
          payload: payload,
        );
      } else if (destination == 'community') {
        final social = SocialService.instance;
        if (!social.cloudEnabled || social.currentUid == null) {
          setState(
            () => _error = _german
                ? 'Melde dich an, um mit der Community zu teilen.'
                : 'Sign in to share with the community.',
          );
          return;
        }
        final at = DateTime.now();
        await social.publishCommunityRun(
          CommunityRun(
            id: '${social.currentUid}_${at.microsecondsSinceEpoch}',
            uid: social.currentUid!,
            displayName: ProgressStore.profileName,
            routeName: payload['name'] as String,
            distanceMeters: (payload['distanceMeters'] as num).toDouble(),
            ascentMeters: (payload['ascentMeters'] as num).toDouble(),
            points: (payload['points'] as List<List<double>>),
            createdAt: at,
            activity: RouteActivity.fromJson(payload['activity'] as Map),
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _german
                  ? 'Aktivität mit der Community geteilt.'
                  : 'Activity shared with the community.',
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final box = context.findRenderObject() as RenderBox?;
        final origin = box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size;
        final file = await RunSnapshotService.save(
          {...widget.route, 'activity': payload['activity']},
          id: 'share_${DateTime.now().microsecondsSinceEpoch}',
          german: _german,
        );
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          text: '${payload['name']} · ${_type.label(_german)}',
          sharePositionOrigin: origin,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _german
              ? 'Teilen fehlgeschlagen. Bitte prüfe deine Verbindung und versuche es erneut.'
              : 'Sharing failed. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .88,
    minChildSize: .5,
    maxChildSize: .96,
    expand: false,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          _german ? 'Aktivität teilen' : 'Share activity',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<RouteActivityType>(
          initialValue: _type,
          decoration: InputDecoration(
            labelText: _german ? 'Aktivitätsart' : 'Activity type',
            border: const OutlineInputBorder(),
          ),
          items: RouteActivityType.values
              .map(
                (t) =>
                    DropdownMenuItem(value: t, child: Text(t.label(_german))),
              )
              .toList(),
          onChanged: _busy
              ? null
              : (type) {
                  if (type != null) {
                    setState(() {
                      _type = type;
                      _preview = {
                        ...widget.route,
                        'activity': _payload['activity'],
                      }..remove('snapshotId');
                    });
                  }
                },
        ),
        const SizedBox(height: 16),
        RunSnapshotPreview(route: _preview),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_busy) const LinearProgressIndicator(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: GreenScreenStyle.accent,
            foregroundColor: Colors.white,
          ),
          onPressed: _busy ? null : () => _send('friends'),
          icon: const Icon(Icons.people_outline),
          label: Text(_german ? 'An Freunde senden' : 'Send to friends'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _send('community'),
          icon: const Icon(Icons.public),
          label: Text(
            _german ? 'Mit der Community teilen' : 'Share with the community',
          ),
        ),
        Text(
          _german
              ? 'In der Community sind Strecke und Messwerte für angemeldete Mitglieder sichtbar.'
              : 'Community posts show the route and metrics to signed-in members.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : () => _send('image'),
          icon: const Icon(Icons.image_outlined),
          label: Text(_german ? 'Routenbild teilen' : 'Share route image'),
        ),
      ],
    ),
  );
}
