import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/workout_video_store.dart';

class ExerciseVideoClip extends StatelessWidget {
  const ExerciseVideoClip({super.key, required this.exercise});
  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final clip = exercise['videoClip'];
    final rest = exercise['restSeconds'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rest is num)
          Text(de ? '$rest s Satzpause' : '$rest s rest between sets'),
        if (clip is Map)
          TextButton.icon(
            icon: const Icon(Icons.play_circle_outline),
            label: Text(de ? 'Übungsvideo' : 'Exercise video'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  _ClipDialog(clip: Map<String, dynamic>.from(clip)),
            ),
          ),
      ],
    );
  }
}

class _ClipDialog extends StatefulWidget {
  const _ClipDialog({required this.clip});
  final Map<String, dynamic> clip;
  @override
  State<_ClipDialog> createState() => _ClipDialogState();
}

class _ClipDialogState extends State<_ClipDialog> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false, _failed = false, _atEnd = false;
  late Duration _start, _end;
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final start = (widget.clip['startSeconds'] as num).toDouble();
      final end = (widget.clip['endSeconds'] as num).toDouble();
      if (!start.isFinite || !end.isFinite || start < 0 || end <= start) {
        throw const FormatException();
      }
      _start = Duration(milliseconds: (start * 1000).round());
      _end = Duration(milliseconds: (end * 1000).round());
      final file = WorkoutVideoStore.file(widget.clip['videoId'] as String);
      if (!await file.exists() || !mounted) throw const FormatException();
      final controller = VideoPlayerController.file(file);
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      if (_end > controller.value.duration) throw const FormatException();
      await controller.seekTo(_start);
      if (!mounted) return;
      setState(() => _ready = true);
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
        if (_checking || _atEnd) return;
        _checking = true;
        try {
          if (controller.value.hasError) throw StateError('Playback failed');
          if (!controller.value.isPlaying) return;
          final position = await controller.position;
          if (!mounted) return;
          if (position != null && position >= _end) {
            _atEnd = true;
            await controller.pause();
            await controller.seekTo(_end);
            if (mounted) setState(() {});
          }
        } catch (_) {
          _timer?.cancel();
          if (mounted) setState(() => _failed = true);
        } finally {
          _checking = false;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_controller?.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    return AlertDialog(
      title: Text(de ? 'Übungsvideo' : 'Exercise video'),
      content: SizedBox(
        width: 360,
        child: _failed
            ? Text(
                de
                    ? 'Video nicht verfügbar. Dein Workout bleibt gespeichert.'
                    : 'Video unavailable. Your workout is still saved.',
              )
            : !_ready
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () async {
                      try {
                        final c = _controller!;
                        if (c.value.isPlaying) {
                          await c.pause();
                        } else {
                          if (_atEnd) {
                            await c.seekTo(_start);
                            _atEnd = false;
                          }
                          await c.play();
                        }
                        if (mounted) setState(() {});
                      } catch (_) {
                        if (mounted) setState(() => _failed = true);
                      }
                    },
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(de ? 'Schließen' : 'Close'),
        ),
      ],
    );
  }
}
