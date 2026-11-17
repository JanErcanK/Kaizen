import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Serves only packaged anatomy assets, on a private per-view loopback port.
class AnatomyAssetServer {
  AnatomyAssetServer._(this._server, this._bundle);

  static const routes = <String, String>{
    '/': 'assets/3d_viewer/index.html',
    '/index.html': 'assets/3d_viewer/index.html',
    '/babylon.js': 'assets/3d_viewer/babylon.js',
    '/anatomy_viewer.js': 'assets/3d_viewer/anatomy_viewer.js',
    '/babylonjs.loaders.min.js': 'assets/3d_viewer/babylonjs.loaders.min.js',
    '/anatomy_config.json': 'assets/3d_viewer/anatomy_config.json',
    '/models/kaizen_anatomy_mobile.glb':
        'assets/models/kaizen_anatomy_mobile.glb',
    '/models/kaizen_anatomy_skeleton.glb':
        'assets/models/kaizen_anatomy_skeleton.glb',
    '/models/kaizen_anatomy_organs.glb':
        'assets/models/kaizen_anatomy_organs.glb',
  };

  final HttpServer _server;
  final AssetBundle _bundle;
  StreamSubscription<HttpRequest>? _requests;

  Uri get uri => Uri.parse('http://127.0.0.1:${_server.port}/');

  static Future<AnatomyAssetServer> start({AssetBundle? bundle}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final result = AnatomyAssetServer._(server, bundle ?? rootBundle);
    result._requests = server.listen(
      (request) => unawaited(result._respond(request)),
    );
    return result;
  }

  Future<void> _respond(HttpRequest request) async {
    try {
      // The asset server is not a proxy and never reads arbitrary file paths.
      final asset = routes[request.uri.path];
      final origin = request.headers.value('origin');
      if (origin != null && origin != uri.origin) {
        request.response.statusCode = HttpStatus.forbidden;
      } else if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
      } else if (asset == null) {
        request.response.statusCode = HttpStatus.notFound;
      } else {
        final data = await _bundle.load(asset);
        request.response.headers.contentType = asset.endsWith('.html')
            ? ContentType.html
            : asset.endsWith('.glb')
            ? ContentType('model', 'gltf-binary')
            : asset.endsWith('.json')
            ? ContentType.json
            : ContentType('application', 'javascript', charset: 'utf-8');
        request.response.headers.set('X-Content-Type-Options', 'nosniff');
        request.response.headers.set(
          HttpHeaders.cacheControlHeader,
          'no-cache',
        );
        request.response.contentLength = data.lengthInBytes;
        if (request.method == 'GET') {
          request.response.add(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        }
      }
      await request.response.close();
    } catch (_) {
      // A view can close while a GLB is being read or sent.
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> close() async {
    await _server.close(force: true);
    await _requests?.cancel();
  }
}
