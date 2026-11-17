import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaizen/services/instagram_video_service.dart';
import 'fixtures/instagram_post_fixture.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kaizen_video_test_');
  });
  tearDown(() async => directory.delete(recursive: true));

  for (final metadata in [
    '<meta content="https://s.cdninstagram.com/video.mp4?a=1&amp;b=2" '
        'property="og:video:secure_url">',
    '<script type="application/ld+json">${jsonEncode({
      '@type': 'SocialMediaPosting',
      'video': {'@type': 'VideoObject', 'contentUrl': 'https://s.cdninstagram.com/video.mp4?a=1&b=2'},
    })}</script>',
  ]) {
    test('downloads public video from ${metadata.substring(0, 12)}', () async {
      final calls = <Uri>[];
      final service = InstagramVideoService(
        client: MockClient((request) async {
          calls.add(request.url);
          expect(request.headers.containsKey('authorization'), isFalse);
          expect(request.followRedirects, isFalse);
          if (request.url.host == 'www.instagram.com') {
            return http.Response(metadata, 200);
          }
          expect(request.url.queryParameters['b'], '2');
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'content-type': 'video/mp4'},
          );
        }),
      );
      addTearDown(service.close);
      final file = await service.download(
        'https://www.instagram.com/reel/abc/',
        directory: directory,
      );
      expect(await file.readAsBytes(), [1, 2, 3]);
      expect(calls, hasLength(2));
    });
  }

  test('follows Instagram share redirects', () async {
    final service = InstagramVideoService(
      client: MockClient((request) async {
        if (request.url.path == '/share/reel/abc') {
          return http.Response('', 302, headers: {'location': '/reel/abc/'});
        }
        if (request.url.host == 'www.instagram.com') {
          return http.Response(
            '<meta property="og:video" '
            'content="https://video.fbcdn.net/clip.mp4">',
            200,
          );
        }
        return http.Response.bytes(
          [1],
          200,
          headers: {'content-type': 'video/mp4'},
        );
      }),
    );
    addTearDown(service.close);
    expect(
      await (await service.download(
        'https://www.instagram.com/share/reel/abc',
        directory: directory,
      )).readAsBytes(),
      [1],
    );
  });

  for (final response in [
    http.Response('Login required', 403),
    http.Response('<html>Log in</html>', 200),
    http.Response(
      '<script>{"recommendations":[{"video_url":'
      '"https://s.cdninstagram.com/other.mp4"}]}</script>',
      200,
    ),
    http.Response(
      '',
      302,
      headers: {'location': 'https://unrelated.example/video'},
    ),
    http.Response(
      '<meta property="og:video" content="https://127.0.0.1/video">',
      200,
    ),
    http.Response(
      '<meta property="og:video" content="https://instagram.com.evil.example/video">',
      200,
    ),
  ]) {
    test(
      'unavailable or unrelated content never becomes a video (${response.body})',
      () async {
        var calls = 0;
        final service = InstagramVideoService(
          client: MockClient((_) async {
            calls++;
            return response;
          }),
        );
        addTearDown(service.close);
        await expectLater(
          service.download(
            'https://www.instagram.com/reel/abc/',
            directory: directory,
          ),
          throwsA(isA<SharedVideoUnavailable>()),
        );
        expect(calls, 1);
        expect(await directory.list().toList(), isEmpty);
      },
    );
  }

  test('rejects oversized downloads and removes temporary files', () async {
    final service = InstagramVideoService(
      client: MockClient.streaming((request, _) async {
        if (request.url.host == 'www.instagram.com') {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                '<meta property="og:video" content="https://s.cdninstagram.com/video.mp4">',
              ),
            ),
            200,
          );
        }
        return http.StreamedResponse(
          const Stream.empty(),
          200,
          contentLength: InstagramVideoService.maxVideoBytes + 1,
          headers: {'content-type': 'video/mp4'},
        );
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.download(
        'https://www.instagram.com/reel/abc/',
        directory: directory,
      ),
      throwsA(isA<SharedVideoUnavailable>()),
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test(
    'imports all nine carousel slides in order even with img_index=6',
    () async {
      final calls = <Uri>[];
      final service = InstagramVideoService(
        client: MockClient((request) async {
          calls.add(request.url);
          if (request.url.path.endsWith('/embed/')) {
            return http.Response(instagramEmbed(), 200);
          }
          if (request.url.host == 'www.instagram.com') {
            return http.Response(instagramPostPage(), 200);
          }
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }),
      );
      addTearDown(service.close);
      final media = await service.downloadPost(
        instagramPostUrl,
        directory: directory,
      );
      expect(media, hasLength(9));
      expect(media.map((m) => m.slideNumber), List.generate(9, (i) => i + 1));
      expect(media.every((m) => !m.isVideo), isTrue);
      expect(
        calls.skip(2).map((u) => u.path),
        List.generate(9, (i) => '/slide_${i + 1}.jpg'),
      );
    },
  );

  for (final embed in [
    instagramEmbed(id: 'unrelated'),
    instagramEmbed(blocked: true),
    instagramEmbed(videoSlide: 6, includeVideoUrl: false),
    instagramEmbed(count: 21),
  ]) {
    test(
      'never substitutes cover/other posts or a partial carousel (${embed.length})',
      () async {
        var mediaCalls = 0;
        final service = InstagramVideoService(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/embed/')) {
              return http.Response(embed, 200);
            }
            if (request.url.host == 'www.instagram.com') {
              return http.Response(instagramPostPage(), 200);
            }
            mediaCalls++;
            return http.Response('unexpected', 200);
          }),
        );
        addTearDown(service.close);
        await expectLater(
          service.downloadPost(instagramPostUrl, directory: directory),
          throwsA(isA<SharedVideoUnavailable>()),
        );
        expect(mediaCalls, 0);
        expect(await directory.list().toList(), isEmpty);
      },
    );
  }

  test('keeps video and image slides distinct', () async {
    final service = InstagramVideoService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/embed/')) {
          return http.Response(instagramEmbed(videoSlide: 6), 200);
        }
        if (request.url.host == 'www.instagram.com') {
          return http.Response(instagramPostPage(), 200);
        }
        return http.Response.bytes(
          [1],
          200,
          headers: {
            'content-type': request.url.path.endsWith('.mp4')
                ? 'video/mp4'
                : 'image/jpeg',
          },
        );
      }),
    );
    addTearDown(service.close);
    final media = await service.downloadPost(
      instagramPostUrl,
      directory: directory,
    );
    expect(media.where((m) => m.isVideo).single.slideNumber, 6);
    expect(media.where((m) => !m.isVideo), hasLength(8));
  });

  test('failed slide download cleans all earlier slides', () async {
    final service = InstagramVideoService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/embed/')) {
          return http.Response(instagramEmbed(), 200);
        }
        if (request.url.host == 'www.instagram.com') {
          return http.Response(instagramPostPage(), 200);
        }
        if (request.url.path.endsWith('slide_6.jpg')) {
          return http.Response('', 403);
        }
        return http.Response.bytes(
          [1],
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }),
    );
    addTearDown(service.close);
    await expectLater(
      service.downloadPost(instagramPostUrl, directory: directory),
      throwsA(isA<SharedVideoUnavailable>()),
    );
    expect(await directory.list().toList(), isEmpty);
  });
}
