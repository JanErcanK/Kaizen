import 'dart:io';

import '../models/ai_chat.dart';
import 'progress_store.dart';

/// Sources are shared by chat frames and saved workouts; chat deletion must not
/// remove them. Only locally imported IDs can be attached by the model.
class WorkoutVideoStore {
  /// Give in-flight imports a day of grace; keep anything referenced by either
  /// chat history or saved workouts, including after the originating chat ends.
  static Future<void> pruneUnused(List<ChatConversation> chats) async {
    try {
      final keep = chats
          .expand((c) => c.messages)
          .expand((m) => m.frames)
          .map((f) => f.videoId)
          .whereType<String>()
          .toSet();
      for (final workout in [
        ...ProgressStore.gymWorkouts,
        ...ProgressStore.calisthenicsWorkouts,
      ]) {
        for (final exercise
            in (workout['exercises'] as List? ?? []).whereType<Map>()) {
          final clip = exercise['videoClip'];
          if (clip is Map && clip['videoId'] is String) {
            keep.add(clip['videoId'] as String);
          }
        }
      }
      final directory = Directory(
        '${ProgressStore.storageDirectory}/workout_videos',
      );
      if (!await directory.exists()) return;
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      await for (final entry in directory.list(followLinks: false)) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (!keep.contains(name) &&
            (await entry.stat()).modified.isBefore(cutoff)) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      /* Cleanup must not prevent saving a chat. */
    }
  }

  static File file(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_]+\.mp4$').hasMatch(id)) {
      throw const FormatException('Invalid video ID');
    }
    return File('${ProgressStore.storageDirectory}/workout_videos/$id');
  }

  static Future<String?> retain(String path) async {
    File? destination;
    try {
      final source = File(path);
      if (await source.length() > 128 * 1024 * 1024) return null;
      final id = '${newChatId()}.mp4';
      destination = file(id);
      await destination.parent.create(recursive: true);
      await source.copy(destination.path);
      return id;
    } on FileSystemException {
      try {
        await destination?.delete();
      } on FileSystemException {
        /* optional */
      }
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> attachClips(
    List<AiWorkoutExercise> exercises,
    List<ChatFrame> frames,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final exercise in exercises) {
      final map = exercise.toWorkoutMap();
      final source = frames
          .where(
            (f) => f.videoId == exercise.sourceVideoId && f.videoId != null,
          )
          .firstOrNull;
      final start = exercise.startSeconds;
      final end = exercise.endSeconds;
      if (source != null &&
          start.isFinite &&
          end.isFinite &&
          start >= 0 &&
          end > start &&
          end <= (source.videoDuration ?? 0)) {
        try {
          if (await file(source.videoId!).exists()) {
            map['videoClip'] = {
              'videoId': source.videoId,
              'startSeconds': start,
              'endSeconds': end,
            };
          }
        } on FileSystemException {
          /* Save the workout without video. */
        } on FormatException {
          /* Ignore invalid legacy references. */
        }
      }
      result.add(map);
    }
    return result;
  }
}
