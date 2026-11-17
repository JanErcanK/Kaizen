import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/services/ai_chat_store.dart';
import 'package:kaizen/services/coach_share_service.dart';
import 'package:kaizen/services/progress_store.dart';

// Explicit live diagnostic, excluded from the normal test/ suite. Uses only
// public Instagram/CDN requests and local decoding; never reads an AI API key.
// The inherited factory restores the real client instead of the test stub.
class _PublicNetwork extends HttpOverrides {}

void main() {
  testWidgets('live nine-slide Instagram post prepares all images for AI', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final storage = await Directory.systemTemp.createTemp(
        'kaizen_live_import_',
      );
      await ProgressStore.init(storageRootPath: storage.path);
      try {
        final imports = await storage.createTemp('imports_');
        final frames = await HttpOverrides.runWithHttpOverrides(
          () => CoachShareService.prepare(
            const CoachSharedInput(
              id: 'live-test',
              text:
                  'https://www.instagram.com/p/De3BL_pCByI/?img_index=6&vrfl=MXQzcnNiYmlldjk1ZQ==',
            ),
            temporaryDirectory: imports,
          ),
          _PublicNetwork(),
        );
        expect(frames, hasLength(9));
        expect(
          frames.map((f) => f.slideNumber),
          List.generate(9, (i) => i + 1),
        );
        var total = 0;
        for (final frame in frames) {
          final bytes = await AiChatStore.imageFile(
            frame.imageName,
          ).readAsBytes();
          expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
          expect(frame.seconds, -1);
          total += bytes.length;
        }
        expect(total, lessThanOrEqualTo(16 * 1024 * 1024));
        expect(await imports.list().toList(), isEmpty);
        // ignore: avoid_print
        print(
          'LIVE IMPORT OK: ${frames.length} decoded images, $total bytes ready for AI; no AI call.',
        );
      } finally {
        // This diagnostic is a Flutter test outside the default test/ directory.
        // ignore: invalid_use_of_visible_for_testing_member
        await ProgressStore.closeForTesting();
        await storage.delete(recursive: true);
      }
    });
  });
}
