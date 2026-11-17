import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Keeps SVG shading at a bounded resolution while gestures scale the image.
/// A 4.5x zoom must not allocate a 4.5x full-screen blur/raster surface.
class CachedBodyPaint extends StatefulWidget {
  const CachedBodyPaint({super.key, required this.painter});

  final CustomPainter painter;

  @override
  State<CachedBodyPaint> createState() => _CachedBodyPaintState();
}

class _CachedBodyPaintState extends State<CachedBodyPaint> {
  ui.Image? _image;
  Size? _size;
  double? _pixelRatio;
  ThemeData? _theme;
  bool _dirty = true;

  @override
  void didUpdateWidget(CachedBodyPaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dirty =
        _dirty ||
        oldWidget.painter.runtimeType != widget.painter.runtimeType ||
        widget.painter.shouldRepaint(oldWidget.painter);
  }

  void _rasterize(Size size, double pixelRatio, ThemeData theme) {
    final ratio = math.min(
      math.min(pixelRatio, 2.0),
      math.min(
        2048 / math.max(size.width, size.height),
        math.sqrt(2000000 / (size.width * size.height)),
      ),
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    widget.painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final ui.Image next;
    try {
      next = picture.toImageSync(
        (size.width * ratio).ceil(),
        (size.height * ratio).ceil(),
      );
    } finally {
      picture.dispose();
    }
    final previous = _image;
    _image = next;
    _size = size;
    _pixelRatio = pixelRatio;
    _theme = theme;
    _dirty = false;
    // Let RawImage update its render object before releasing the old handle.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
        if (_dirty ||
            _size != size ||
            _pixelRatio != pixelRatio ||
            _theme != theme) {
          _rasterize(size, pixelRatio, theme);
        }
        return RawImage(
          image: _image,
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}
