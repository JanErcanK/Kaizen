import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'anatomy_webview.dart';

/// Keeps one renderer and its loaded GLBs alive while its single native surface
/// moves between the home slot and fullscreen. The old surface must unmount
/// before another owner attaches; the session belongs to the home body card.
class AnatomySceneSession {
  AnatomySceneSession({AnatomyWebViewFactory? factory})
    : _factory = factory ?? createAnatomyWebView;

  final AnatomyWebViewFactory _factory;
  AnatomyWebView? _view;
  Future<void>? _initializing;
  Object? _owner;
  ValueChanged<Object?>? _onMessage;
  ValueChanged<String>? _onError;
  VoidCallback? _onPageFinished;
  bool _disposed = false;
  String? loadedMode;
  bool transitioning = false;
  int _captureId = 0;
  final _captures = <String, Completer<Uint8List?>>{};

  Future<AnatomyWebView?> attach({
    required Object owner,
    required Map<String, Object?> initialState,
    required Color backgroundColor,
    required ValueChanged<Object?> onMessage,
    required ValueChanged<String> onError,
    required VoidCallback onPageFinished,
  }) async {
    if (_disposed) return null;
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError('An anatomy scene cannot attach to two surfaces.');
    }
    _owner = owner;
    _onMessage = onMessage;
    _onError = onError;
    _onPageFinished = onPageFinished;
    if (_initializing == null) {
      final view = _view = _factory();
      if (view == null) return null;
      _initializing = view.initialize(
        initialState: initialState,
        backgroundColor: backgroundColor,
        onMessage: _receive,
        onError: (message) => _onError?.call(message),
        onPageFinished: () => _onPageFinished?.call(),
      );
    }
    await _initializing;
    return _disposed || !identical(_owner, owner) ? null : _view;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _onMessage = null;
    _onError = null;
    _onPageFinished = null;
  }

  void _receive(Object? message) {
    Object? decoded = message;
    try {
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is Map) {
        if (decoded['type'] == 'loaded') {
          if (decoded['mode'] is String) loadedMode = decoded['mode'] as String;
        } else if (decoded['type'] == 'transitionFrame') {
          final pending = _captures.remove(decoded['requestId']);
          if (pending == null) return;
          final data = decoded['dataUrl'];
          Uint8List? bytes;
          if (data is String &&
              data.startsWith('data:image/png;base64,') &&
              data.length < 12 * 1024 * 1024) {
            bytes = base64Decode(data.substring(data.indexOf(',') + 1));
          }
          pending.complete(bytes);
          return;
        }
      }
    } on FormatException {
      // Invalid capture data falls back to the live renderer after timeout.
    }
    if (!_disposed) _onMessage?.call(message);
  }

  Future<Uint8List?> captureFrame() async {
    if (_disposed || _view == null || loadedMode == null) return null;
    final id = 'flight-${++_captureId}';
    final result = Completer<Uint8List?>();
    _captures[id] = result;
    transitioning = true;
    try {
      unawaited(
        _view!
            .runJavaScript(
              'window.kaizenAnatomy?.captureFrame(${jsonEncode(id)});',
            )
            .catchError((Object _) {
              if (!result.isCompleted) result.complete(null);
            }),
      );
      return await result.future.timeout(
        const Duration(milliseconds: 350),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      _captures.remove(id);
    }
  }

  Future<void> resume() async {
    transitioning = false;
    if (_disposed) return;
    try {
      await _view?.runJavaScript(
        'window.kaizenAnatomy?.setState({paused:false});',
      );
    } catch (_) {
      // A platform surface can finish retiring when the app leaves Home.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _owner = null;
    _onMessage = null;
    _onError = null;
    _onPageFinished = null;
    for (final pending in _captures.values) {
      if (!pending.isCompleted) pending.complete(null);
    }
    _captures.clear();
    await _view?.dispose();
    _view = null;
  }
}
