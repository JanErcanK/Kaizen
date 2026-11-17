import 'dart:io';

import 'package:kaizen/services/instagram_video_service.dart';

/// Optional live check: `dart run tool/check_public_video.dart <Instagram URL>`
/// Does not call an AI provider or use account credentials.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/check_public_video.dart <Instagram URL>',
    );
    exitCode = 64;
    return;
  }
  final directory = await Directory.systemTemp.createTemp('kaizen_live_video_');
  final service = InstagramVideoService();
  try {
    final media = await service.downloadPost(args.single, directory: directory);
    stdout.writeln('Public post downloaded: ${media.length} media items');
    for (final item in media) {
      stdout.writeln(
        '${item.slideNumber ?? 1}: ${item.isVideo ? "video" : "image"}, ${await item.file.length()} bytes',
      );
    }
  } on SharedVideoUnavailable {
    stdout.writeln('Public post unavailable. Chat must request an attachment.');
    exitCode = 2;
  } finally {
    service.close();
    await directory.delete(recursive: true);
  }
}
