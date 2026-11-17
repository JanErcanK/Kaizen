import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/services/anatomy_asset_server.dart';

class _Assets extends CachingAssetBundle {
  final loaded = <String>[];
  @override
  Future<ByteData> load(String key) async {
    loaded.add(key);
    // Offset checks catch accidentally serving an entire shared buffer.
    return ByteData.sublistView(Uint8List.fromList([99, 1, 2, 3, 98]), 1, 4);
  }
}

class _RealHttp extends HttpOverrides {}

void main() {
  test(
    'loopback serves only packaged routes and rejects foreign origins',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final assets = _Assets();
        final server = await AnatomyAssetServer.start(bundle: assets);
        final client = HttpClient();
        try {
          expect(server.uri.host, '127.0.0.1');
          for (final path in AnatomyAssetServer.routes.keys) {
            final request = await client.getUrl(server.uri.resolve(path));
            final response = await request.close();
            expect(response.statusCode, 200, reason: path);
            expect(await response.expand((bytes) => bytes).toList(), [1, 2, 3]);
          }
          expect(assets.loaded, AnatomyAssetServer.routes.values.toList());
          final readCount = assets.loaded.length;
          for (final path in [
            '/secret.txt',
            '/models/other.glb',
            '/../pubspec.yaml',
          ]) {
            final response = await (await client.getUrl(
              server.uri.resolve(path),
            )).close();
            expect(response.statusCode, 404);
            await response.drain<void>();
          }
          final foreign = await client.getUrl(server.uri);
          foreign.headers.set('Origin', 'https://example.invalid');
          final rejected = await foreign.close();
          expect(rejected.statusCode, 403);
          await rejected.drain<void>();
          final post = await client.postUrl(server.uri);
          post.add(utf8.encode('ignored'));
          final postResponse = await post.close();
          expect(postResponse.statusCode, 405);
          await postResponse.drain<void>();
          expect(assets.loaded.length, readCount);
        } finally {
          client.close(force: true);
          await server.close();
        }
      }, _RealHttp());
    },
  );
}
