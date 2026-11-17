import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile;
import 'package:webview_windows/webview_windows.dart' as windows;

import '../services/anatomy_asset_server.dart';
import 'anatomy_webview.dart';

AnatomyWebView? createAnatomyWebView() {
  // Widget tests deliberately exercise the fallback, without native channels
  // or sockets. Tests of the bridge inject their own adapter instead.
  if (Platform.environment.containsKey('FLUTTER_TEST') ||
      WidgetsBinding.instance.runtimeType.toString().contains(
        'TestWidgetsFlutterBinding',
      )) {
    return null;
  }
  if (!Platform.isWindows && !Platform.isAndroid && !Platform.isIOS) {
    return null;
  }
  return _NativeAnatomyWebView();
}

class _NativeAnatomyWebView implements AnatomyWebView {
  windows.WebviewController? _windows;
  mobile.WebViewController? _mobile;
  AnatomyAssetServer? _server;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Future<void>? _initializing;
  bool _disposed = false;
  bool _windowsInitialized = false;

  @override
  Future<void> initialize({
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  }) => _initializing ??= _initialize(
    initialState,
    backgroundColor,
    onMessage,
    onError,
    onPageFinished,
  );

  Future<void> _initialize(
    Map<String, Object?> state,
    Color background,
    ValueChanged<Object?> onMessage,
    ValueChanged<String> onError,
    VoidCallback onPageFinished,
  ) async {
    final server = _server = await AnatomyAssetServer.start();
    if (_disposed) return;
    final uri = server.uri.replace(
      queryParameters: {
        for (final key in ['mode', 'expanded', 'theme', 'locale'])
          key: '${state[key]}',
      },
    );
    bool isLocal(String value) {
      final parsed = Uri.tryParse(value);
      return parsed?.scheme == 'http' &&
          parsed?.host == '127.0.0.1' &&
          parsed?.port == server.uri.port;
    }

    if (Platform.isWindows) {
      final controller = _windows = windows.WebviewController();
      await controller.initialize();
      _windowsInitialized = true;
      if (_disposed) return;
      await controller.setPopupWindowPolicy(
        windows.WebviewPopupWindowPolicy.deny,
      );
      await controller.setBackgroundColor(background);
      _subscriptions.add(
        controller.webMessage.listen((message) {
          if (!_disposed) onMessage(message);
        }),
      );
      _subscriptions.add(
        controller.onLoadError.listen((error) {
          if (!_disposed) onError('$error');
        }),
      );
      _subscriptions.add(
        controller.loadingState.listen((state) {
          if (!_disposed && state == windows.LoadingState.navigationCompleted) {
            onPageFinished();
          }
        }),
      );
      _subscriptions.add(
        controller.url.listen((url) {
          if (!_disposed && url != 'about:blank' && !isLocal(url)) {
            unawaited(controller.stop());
            onError('Navigation outside the local anatomy viewer was blocked.');
          }
        }),
      );
      await controller.loadUrl(uri.toString());
    } else {
      final controller = _mobile = mobile.WebViewController();
      await controller.setJavaScriptMode(mobile.JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(background);
      await controller.addJavaScriptChannel(
        'KaizenBridge',
        onMessageReceived: (message) {
          if (!_disposed) onMessage(message.message);
        },
      );
      await controller.setNavigationDelegate(
        mobile.NavigationDelegate(
          onNavigationRequest: (request) => isLocal(request.url)
              ? mobile.NavigationDecision.navigate
              : mobile.NavigationDecision.prevent,
          onPageFinished: (_) {
            if (!_disposed) onPageFinished();
          },
          onWebResourceError: (error) {
            if (!_disposed && error.isForMainFrame != false) {
              onError(error.description);
            }
          },
        ),
      );
      if (!_disposed) await controller.loadRequest(uri);
    }
  }

  @override
  Widget buildView() {
    if (_windows case final controller?) {
      return windows.Webview(
        controller,
        permissionRequested: (_, _, _) async =>
            windows.WebviewPermissionDecision.deny,
      );
    }
    if (_mobile case final controller?) {
      return mobile.WebViewWidget(
        controller: controller,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      );
    }
    return const SizedBox.expand();
  }

  @override
  Future<void> runJavaScript(String script) async {
    if (_disposed) return;
    if (_windowsInitialized) await _windows?.executeScript(script);
    await _mobile?.runJavaScript(script);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _initializing;
    } catch (_) {}
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    if (_windowsInitialized) await _windows?.dispose();
    // webview_flutter's platform view is released when its Widget unmounts.
    _mobile = null;
    await _server?.close();
  }
}
