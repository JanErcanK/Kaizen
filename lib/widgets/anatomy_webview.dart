import 'package:flutter/widgets.dart';

import 'anatomy_webview_stub.dart'
    if (dart.library.io) 'anatomy_webview_native.dart'
    as platform;

/// One adapter belongs to one widget. It must never be attached twice.
abstract class AnatomyWebView {
  Future<void> initialize({
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  });

  Widget buildView();
  Future<void> runJavaScript(String script);
  Future<void> dispose();
}

typedef AnatomyWebViewFactory = AnatomyWebView? Function();

AnatomyWebView? createAnatomyWebView() => platform.createAnatomyWebView();
