import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class SharedVideoUnavailable implements Exception {
  const SharedVideoUnavailable();
}

class InstagramMediaFile {
  const InstagramMediaFile(
    this.file, {
    required this.isVideo,
    this.slideNumber,
  });
  final File file;
  final bool isVideo;
  final int? slideNumber;
}

class _MediaSource {
  const _MediaSource(this.uri, {required this.isVideo, this.slideNumber});
  final Uri uri;
  final bool isVideo;
  final int? slideNumber;
}

/// Best-effort access to video published on the public post page. No login,
/// private API, third-party downloader, or AI credentials are used here.
class InstagramVideoService {
  InstagramVideoService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const maxVideoBytes = 128 * 1024 * 1024;
  static const _maxPageBytes = 4 * 1024 * 1024;

  void close() => _client.close();

  static bool _hostIs(Uri uri, String domain) =>
      uri.host == domain || uri.host.endsWith('.$domain');

  static bool _allowed(Uri uri, {required bool media}) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      (_hostIs(uri, 'instagram.com') ||
          (media &&
              (_hostIs(uri, 'cdninstagram.com') || _hostIs(uri, 'fbcdn.net'))));

  Future<File> download(String url, {required Directory directory}) async {
    final files = await downloadPost(url, directory: directory);
    if (files.length == 1 && files.single.isVideo) return files.single.file;
    await files.first.file.parent.delete(recursive: true);
    throw const SharedVideoUnavailable();
  }

  /// Imports the full post in slide order; img_index is a viewing position,
  /// not a request to discard the other exercises in a carousel.
  Future<List<InstagramMediaFile>> downloadPost(
    String url, {
    required Directory directory,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_allowed(uri, media: false)) {
      throw const SharedVideoUnavailable();
    }
    // A private temporary directory prevents concurrent imports overwriting one
    // another. The caller deletes it after local frame extraction.
    final folder = await directory.createTemp('coach_video_');
    final deadline = Timer(const Duration(seconds: 90), close);
    try {
      return await _downloadPost(uri, folder);
    } catch (_) {
      if (await folder.exists()) await folder.delete(recursive: true);
      throw const SharedVideoUnavailable();
    } finally {
      deadline.cancel();
    }
  }

  Future<String> _page(Uri uri) async {
    final page = await _get(uri, media: false);
    final bytes = <int>[];
    await for (final chunk in page.stream.timeout(
      const Duration(seconds: 20),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > _maxPageBytes) {
        throw const SharedVideoUnavailable();
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<List<InstagramMediaFile>> _downloadPost(
    Uri uri,
    Directory folder,
  ) async {
    final html = await _page(uri);
    final video = _videoUrl(html);
    List<_MediaSource>? sources;
    if (video != null) sources = [_MediaSource(video, isVideo: true)];
    if (sources == null) {
      // Only try the public embed when the public page identifies this exact
      // post. Login/error pages and unrelated recommendations are not evidence.
      final canonical = _publicPost(html, uri);
      if (canonical != null) {
        final shortcode = _shortcode(canonical)!;
        sources = _embeddedMedia(html, shortcode);
        sources ??= _embeddedMedia(
          await _page(Uri.https('www.instagram.com', '/p/$shortcode/embed/')),
          shortcode,
        );
      }
    }
    if (sources == null || sources.isEmpty || sources.length > 20) {
      throw const SharedVideoUnavailable();
    }
    final files = <InstagramMediaFile>[];
    var remaining = maxVideoBytes;
    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final file = await _downloadMedia(source, folder, i, remaining);
      remaining -= await file.length();
      files.add(
        InstagramMediaFile(
          file,
          isVideo: source.isVideo,
          slideNumber: source.slideNumber,
        ),
      );
    }
    return files;
  }

  Future<File> _downloadMedia(
    _MediaSource source,
    Directory folder,
    int index,
    int remaining,
  ) async {
    if (remaining <= 0) throw const SharedVideoUnavailable();
    final response = await _get(source.uri, media: true);
    final mime = response.headers['content-type']?.split(';').first.trim();
    if (mime == null ||
        !(mime.startsWith(source.isVideo ? 'video/' : 'image/') ||
            (source.isVideo && mime == 'application/octet-stream'))) {
      await response.stream.listen(null).cancel();
      throw const SharedVideoUnavailable();
    }
    final mediaLimit = source.isVideo ? maxVideoBytes : 25 * 1024 * 1024;
    final limit = remaining < mediaLimit ? remaining : mediaLimit;
    if ((response.contentLength ?? 0) > limit) {
      await response.stream.listen(null).cancel();
      throw const SharedVideoUnavailable();
    }
    final file = File(
      '${folder.path}/$index.${source.isVideo ? "mp4" : "image"}',
    );
    final output = await file.open(mode: FileMode.write);
    var size = 0;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 20),
      )) {
        size += chunk.length;
        if (size > limit) throw const SharedVideoUnavailable();
        await output.writeFrom(chunk);
      }
    } finally {
      await output.close();
    }
    if (size == 0) throw const SharedVideoUnavailable();
    return file;
  }

  Future<http.StreamedResponse> _get(Uri uri, {required bool media}) async {
    for (var redirects = 0; redirects <= 4; redirects++) {
      if (!_allowed(uri, media: media)) throw const SharedVideoUnavailable();
      final response = await _client
          .send(
            http.Request('GET', uri)
              ..followRedirects = false
              ..headers['User-Agent'] = 'Kaizen/1.1 (public video import)'
              ..headers['Accept'] = media ? 'video/*, image/*' : 'text/html',
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              close();
              throw const SharedVideoUnavailable();
            },
          );
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        await response.stream.listen(null).cancel();
        final location = response.headers['location'];
        if (location == null) throw const SharedVideoUnavailable();
        uri = uri.resolve(location);
        continue;
      }
      final limit = media ? maxVideoBytes : _maxPageBytes;
      if (response.statusCode != 200 || (response.contentLength ?? 0) > limit) {
        await response.stream.listen(null).cancel();
        throw const SharedVideoUnavailable();
      }
      return response;
    }
    throw const SharedVideoUnavailable();
  }

  static Uri? _videoUrl(String html) {
    Uri? mediaUri(Object? value) {
      if (value is! String) return null;
      final uri = Uri.tryParse(_entities(value));
      return uri != null && _allowed(uri, media: true) ? uri : null;
    }

    for (final attributes in _metaTags(html)) {
      final property = (attributes['property'] ?? attributes['name'])
          ?.toLowerCase();
      if ([
        'og:video',
        'og:video:url',
        'og:video:secure_url',
      ].contains(property)) {
        final uri = mediaUri(attributes['content']);
        if (uri != null) return uri;
      }
    }
    // JSON-LD describes the post itself. Do not scan arbitrary script URLs:
    // they can belong to recommendations instead of the shared video.
    Uri? fromJson(Object? value) {
      if (value is List) {
        for (final item in value) {
          final uri = fromJson(item);
          if (uri != null) return uri;
        }
      } else if (value is Map) {
        if (value['@type'] == 'VideoObject') {
          final uri = mediaUri(value['contentUrl']);
          if (uri != null) return uri;
        }
        for (final key in ['@graph', 'video', 'mainEntity']) {
          final uri = fromJson(value[key]);
          if (uri != null) return uri;
        }
      }
      return null;
    }

    for (final script in RegExp(
      r'''<script\b[^>]*\btype\s*=\s*["']application/ld\+json["'][^>]*>(.*?)</script\s*>''',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html)) {
      try {
        final uri = fromJson(jsonDecode(script.group(1)!));
        if (uri != null) return uri;
      } on FormatException {
        // A malformed metadata block is not usable video evidence.
      }
    }
    return null;
  }

  static Iterable<Map<String, String>> _metaTags(String html) sync* {
    for (final tag in RegExp(
      r'<meta\b[^>]*>',
      caseSensitive: false,
    ).allMatches(html)) {
      final attributes = <String, String>{};
      for (final attr in RegExp(
        r'''([\w:-]+)\s*=\s*(["'])(.*?)\2''',
        dotAll: true,
      ).allMatches(tag.group(0)!)) {
        attributes[attr.group(1)!.toLowerCase()] = attr.group(3)!;
      }
      yield attributes;
    }
  }

  static String? _shortcode(Uri uri) {
    final segments = uri.pathSegments;
    for (var i = 0; i + 1 < segments.length; i++) {
      if (['p', 'reel', 'reels', 'tv'].contains(segments[i]) &&
          RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segments[i + 1])) {
        return segments[i + 1];
      }
    }
    return null;
  }

  static Uri? _publicPost(String html, Uri requested) {
    for (final tag in _metaTags(html)) {
      if (tag['property'] != 'og:url') continue;
      final uri = Uri.tryParse(_entities(tag['content'] ?? ''));
      if (uri == null || !_allowed(uri, media: false)) continue;
      final id = _shortcode(uri);
      if (id != null &&
          (_shortcode(requested) == id || _shortcode(requested) == null)) {
        return uri;
      }
    }
    return null;
  }

  static List<_MediaSource>? _embeddedMedia(String html, String shortcode) {
    // Instagram publishes a JSON-encoded context for its public embed player.
    // Decode that exact context, requiring the requested shortcode at both
    // levels. A cover image, profile photo or another post must never stand in
    // for missing video/slide content.
    for (final match in RegExp(
      r'"contextJSON"\s*:\s*("(?:\\.|[^"\\])*")',
    ).allMatches(html)) {
      try {
        final decoded = jsonDecode(jsonDecode(match.group(1)!) as String);
        if (decoded is! Map ||
            decoded['context'] is! Map ||
            decoded['gql_data'] is! Map) {
          continue;
        }
        final context = decoded['context'] as Map;
        final media = (decoded['gql_data'] as Map)['shortcode_media'];
        if (context['shortcode'] != shortcode ||
            context['copyright_blocked'] == true ||
            media is! Map ||
            media['shortcode'] != shortcode) {
          continue;
        }
        final sidecar = media['edge_sidecar_to_children'];
        final List nodes;
        if (sidecar is Map && sidecar['edges'] is List) {
          nodes = (sidecar['edges'] as List)
              .map((e) => e is Map ? e['node'] : null)
              .toList();
        } else if (media['__typename'] == 'GraphSidecar') {
          continue;
        } else {
          nodes = [media];
        }
        if (nodes.isEmpty || nodes.length > 20) continue;
        final sources = <_MediaSource>[];
        for (var i = 0; i < nodes.length; i++) {
          final node = nodes[i];
          if (node is! Map || node['is_video'] is! bool) break;
          final isVideo = node['is_video'] as bool;
          final raw = node[isVideo ? 'video_url' : 'display_url'];
          final uri = raw is String ? Uri.tryParse(_entities(raw)) : null;
          if (uri == null || !_allowed(uri, media: true)) break;
          sources.add(
            _MediaSource(
              uri,
              isVideo: isVideo,
              slideNumber: nodes.length > 1 || !isVideo ? i + 1 : null,
            ),
          );
        }
        if (sources.length == nodes.length) return sources;
      } on FormatException {
        // Keep looking only for another valid context, never arbitrary URLs.
      }
    }
    return null;
  }

  static String _entities(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(x[0-9a-fA-F]+|[0-9]+);'), (match) {
        final raw = match.group(1)!;
        final number = int.tryParse(
          raw.startsWith('x') ? raw.substring(1) : raw,
          radix: raw.startsWith('x') ? 16 : 10,
        );
        return number != null && number <= 0x10ffff
            ? String.fromCharCode(number)
            : match.group(0)!;
      });
}
