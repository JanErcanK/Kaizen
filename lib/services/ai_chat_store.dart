import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ai_chat.dart';
import 'progress_store.dart';
import 'workout_video_store.dart';

class AiChatStore {
  static const _secrets = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> apiKey(AiProvider provider) =>
      _secrets.read(key: 'kaizen_ai_${provider.name}');
  static Future<void> saveKey(AiProvider provider, String key) =>
      _secrets.write(key: 'kaizen_ai_${provider.name}', value: key.trim());
  static Future<void> deleteKey(AiProvider provider) =>
      _secrets.delete(key: 'kaizen_ai_${provider.name}');

  static List<ChatConversation> load() {
    final chats = <ChatConversation>[];
    for (final json in ProgressStore.savedChats) {
      try {
        chats.add(ChatConversation.fromJson(json));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return chats;
  }

  static Future<void> save(List<ChatConversation> chats) async {
    await ProgressStore.saveChats(chats.map((c) => c.toJson()).toList());
    await WorkoutVideoStore.pruneUnused(chats);
  }

  static File imageFile(String name) {
    if (!RegExp(r'^[a-zA-Z0-9_]+\.(jpg|png|webp)$').hasMatch(name)) {
      throw const FormatException('Invalid local image name');
    }
    return File('${ProgressStore.storageDirectory}/chat_images/$name');
  }

  static Future<String> saveImage(Uint8List bytes, String mime) async {
    final extension = mime == 'image/png'
        ? 'png'
        : mime == 'image/webp'
        ? 'webp'
        : 'jpg';
    final name = '${newChatId()}.$extension';
    final file = imageFile(name);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return name;
  }

  static Future<void> deleteImages(ChatConversation chat) async {
    for (final message in chat.messages) {
      for (final name in {
        if (message.imageName != null) message.imageName!,
        ...message.frames.map((f) => f.imageName),
      }) {
        final file = imageFile(name);
        if (await file.exists()) await file.delete();
      }
    }
  }
}
