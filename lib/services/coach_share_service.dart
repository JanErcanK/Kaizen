import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ai_chat.dart';
import 'ai_chat_store.dart';
import 'workout_video_store.dart';
import 'chat_image_service.dart';
import 'instagram_video_service.dart';

class CoachSharedInput {
  const CoachSharedInput({
    required this.id,
    this.text = '',
    this.files = const [],
    this.error,
  });
  final String id, text;
  final List<Map<String, dynamic>> files;
  final String? error;
  factory CoachSharedInput.fromJson(Map<String, dynamic> json) =>
      CoachSharedInput(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        error: json['error'] as String?,
        files: (json['files'] as List? ?? [])
            .map((f) => Map<String, dynamic>.from(f as Map))
            .toList(),
      );
}

class CoachShareService {
  static const channel = MethodChannel('de.jankilic.kaizen/coach_share');
  static final pending = ValueNotifier<List<CoachSharedInput>>([]);
  static bool _started = false;
  static Future<void> start() async {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await refresh();
    });
    await refresh();
  }

  static Future<void> refresh() async {
    try {
      final raw = await channel.invokeMethod<String>('pending');
      pending.value = (jsonDecode(raw ?? '[]') as List)
          .map(
            (s) =>
                CoachSharedInput.fromJson(Map<String, dynamic>.from(s as Map)),
          )
          .toList();
    } on MissingPluginException {
      /* Desktop previews have no Android inbox. */
    }
  }

  static Future<void> acknowledge(String id) async {
    if (Platform.isAndroid) {
      await channel.invokeMethod<void>('acknowledge', {'id': id});
    }
    pending.value = pending.value.where((s) => s.id != id).toList();
  }

  static Future<List<ChatFrame>> videoFrames(
    String path, {
    int maxFrames = 48,
  }) async {
    final data = await channel.invokeMapMethod<String, dynamic>('videoFrames', {
      'path': path,
      'maxFrames': maxFrames,
    });
    final videoId = await WorkoutVideoStore.retain(path);
    final frames = <ChatFrame>[];
    try {
      for (final raw in data?['frames'] as List? ?? []) {
        final frame = Map<String, dynamic>.from(raw as Map);
        final bytes = frame['bytes'] as Uint8List;
        if (frames.length >= 48 || bytes.length > 1024 * 1024) {
          throw const FormatException('Video frame limit');
        }
        frames.add(
          ChatFrame(
            imageName: await AiChatStore.saveImage(bytes, 'image/jpeg'),
            seconds: (frame['seconds'] as num).toDouble(),
            videoId: videoId,
            videoDuration: (data?['durationSeconds'] as num?)?.toDouble(),
          ),
        );
      }
      if (frames.isEmpty) throw const FormatException('No video frames');
      return frames;
    } catch (_) {
      for (final frame in frames) {
        final file = AiChatStore.imageFile(frame.imageName);
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
  }

  static Future<List<ChatFrame>> prepare(
    CoachSharedInput input, {
    InstagramVideoService? instagram,
    Directory? temporaryDirectory,
  }) async {
    if (input.error != null) {
      throw const FormatException('Shared content unavailable');
    }
    if (input.files.isEmpty) {
      final url = socialUrl(input.text);
      if (url == null) return [];
      final resolver = instagram ?? InstagramVideoService();
      List<InstagramMediaFile> media = [];
      final frames = <ChatFrame>[];
      try {
        media = await resolver.downloadPost(
          url,
          directory: temporaryDirectory ?? await getTemporaryDirectory(),
        );
        final videos = media.where((m) => m.isVideo).length;
        final images = media.length - videos;
        final perVideo = videos == 0 ? 48 : (48 - images) ~/ videos;
        for (final item in media) {
          if (item.isVideo) {
            final samples = await videoFrames(
              item.file.path,
              maxFrames: perVideo,
            );
            frames.addAll(
              samples.map(
                (frame) => ChatFrame(
                  imageName: frame.imageName,
                  seconds: frame.seconds,
                  videoId: frame.videoId,
                  videoDuration: frame.videoDuration,
                  slideNumber: item.slideNumber,
                ),
              ),
            );
          } else {
            final bytes = await ChatImageService.prepare(XFile(item.file.path));
            frames.add(
              ChatFrame(
                imageName: await AiChatStore.saveImage(bytes, 'image/png'),
                seconds: -1,
                slideNumber: item.slideNumber,
              ),
            );
          }
        }
        return frames;
      } catch (_) {
        for (final frame in frames) {
          final file = AiChatStore.imageFile(frame.imageName);
          if (await file.exists()) await file.delete();
        }
        rethrow;
      } finally {
        resolver.close();
        if (media.isNotEmpty && await media.first.file.parent.exists()) {
          await media.first.file.parent.delete(recursive: true);
        }
      }
    }
    final first = input.files.first;
    if ((first['mime'] as String).startsWith('video/')) {
      return videoFrames(first['path'] as String);
    }
    final frames = <ChatFrame>[];
    for (final file in input.files.take(8)) {
      final bytes = await ChatImageService.prepare(
        XFile(file['path'] as String),
      );
      frames.add(
        ChatFrame(
          imageName: await AiChatStore.saveImage(bytes, 'image/png'),
          seconds: -1, // Screenshots have no known video timestamp.
        ),
      );
    }
    return frames;
  }

  static String? socialUrl(String text) {
    for (final match in RegExp(r'https?://[^\s<>]+').allMatches(text)) {
      final raw = match.group(0)!.replaceFirst(RegExp(r'[).,;]+$'), '');
      final uri = Uri.tryParse(raw);
      final host = uri?.host.toLowerCase() ?? '';
      if ([
        'instagram.com',
        'tiktok.com',
        'youtube.com',
        'youtu.be',
      ].any((h) => host == h || host.endsWith('.$h'))) {
        return raw;
      }
    }
    return null;
  }
}
