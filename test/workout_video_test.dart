import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/models/ai_chat.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/services/workout_video_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('workout_video_test');
    await ProgressStore.init(storageRootPath: root.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await root.delete(recursive: true);
  });
  AiWorkoutExercise exercise(String id, {double start = 2, double end = 7}) =>
      AiWorkoutExercise(
        name: 'Push-up',
        sets: 3,
        reps: 12,
        mainGroup: 'Brust',
        secondaryMuscles: const [],
        restSeconds: 90,
        sourceVideoId: id,
        startSeconds: start,
        endSeconds: end,
      );

  test(
    'retained source and clip survive chat deletion and workout reopen',
    () async {
      final source = await File(
        '${root.path}/source.mp4',
      ).writeAsBytes([1, 2, 3]);
      final id = (await WorkoutVideoStore.retain(source.path))!;
      await source.delete();
      final frame = ChatFrame.fromJson(
        ChatFrame(
          imageName: 'sample.jpg',
          seconds: 2,
          videoId: id,
          videoDuration: 10,
        ).toJson(),
      );
      final parsed = AiWorkoutExercise.fromJson(exercise(id).toJson());
      final maps = await WorkoutVideoStore.attachClips([parsed], [frame]);
      final saved = await ProgressStore.saveAiWorkout(
        sourceId: 'clip_test',
        name: 'Video workout',
        category: 'gym',
        exercises: maps,
      );
      await AiChatStore.deleteImages(
        ChatConversation(
          id: 'chat',
          provider: AiProvider.openai,
          model: 'test',
          title: 'test',
          messages: [
            ChatMessage(
              id: 'message',
              role: 'user',
              text: '',
              createdAt: DateTime.now(),
              frames: [frame],
            ),
          ],
        ),
      );
      await WorkoutVideoStore.file(
        id,
      ).setLastModified(DateTime.now().subtract(const Duration(days: 2)));
      final orphan = await WorkoutVideoStore.file(
        'unused.mp4',
      ).writeAsBytes([1]);
      await orphan.setLastModified(
        DateTime.now().subtract(const Duration(days: 2)),
      );
      await WorkoutVideoStore.pruneUnused([]);
      expect(await orphan.exists(), isFalse);
      expect(await WorkoutVideoStore.file(id).exists(), isTrue);
      await ProgressStore.closeForTesting();
      await ProgressStore.init(storageRootPath: root.path);
      final stored =
          (ProgressStore.gymWorkoutById(saved.id)!['exercises'] as List).single
              as Map;
      expect(stored['videoClip']['startSeconds'], 2);
      expect(stored['restSeconds'], 90);
      expect(stored['sets'], 3);
    },
  );

  test(
    'missing files, unknown sources and invalid ranges never block saving',
    () async {
      final id = 'missing.mp4';
      final frames = [
        ChatFrame(
          imageName: 'sample.jpg',
          seconds: 2,
          videoId: id,
          videoDuration: 10,
        ),
      ];
      for (final e in [
        exercise(id),
        exercise('unknown.mp4'),
        exercise(id, start: -1),
        exercise(id, end: 11),
        exercise(id, end: 1),
        exercise(id, end: double.nan),
      ]) {
        final maps = await WorkoutVideoStore.attachClips([e], frames);
        expect(maps.single.containsKey('videoClip'), isFalse);
        final saved = await ProgressStore.saveAiWorkout(
          sourceId: newChatId(),
          name: 'No video',
          category: 'calisthenics',
          exercises: maps,
        );
        expect(ProgressStore.calisthenicsWorkoutById(saved.id), isNotNull);
      }
      expect(
        await WorkoutVideoStore.retain('${root.path}/nonexistent.mp4'),
        isNull,
      );
      expect(
        () => WorkoutVideoStore.file('../outside.mp4'),
        throwsFormatException,
      );
    },
  );
}
