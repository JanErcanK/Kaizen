import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Bound upload/decode costs and strip metadata. Keep only the resized image.
class ChatImageService {
  static Future<Uint8List> prepare(XFile file) async {
    if (await file.length() > 25 * 1024 * 1024) {
      throw const FormatException('Image too large');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await file.readAsBytes(),
    );
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale = min(1.0, 1280 / max(descriptor.width, descriptor.height));
      codec = await descriptor.instantiateCodec(
        targetWidth: max(1, (descriptor.width * scale).round()),
        targetHeight: max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > 4 * 1024 * 1024) {
        throw const FormatException('Image too large');
      }
      return data.buffer.asUint8List();
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
