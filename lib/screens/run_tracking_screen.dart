import '../widgets/app_back_button.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../navigation/app_tab_navigation.dart';
import '../models/route_activity.dart';
import '../services/run_snapshot_service.dart';
import '../widgets/run_share_sheet.dart';
import '../services/progress_store.dart';
import '../services/calorie_burn_service.dart';
import '../services/workout_tts_service.dart';
import '../services/social/social_service.dart';
import '../services/social/live_run_publisher.dart';
import '../theme/app_colors.dart';
import '../widgets/run_route_visuals.dart';

/// Live tracking screen for an already-planned route.
/// Provides:
/// - Green heading-aware position marker, auto-following camera
/// - Planned polyline (dimmed) + actually walked polyline (primary color)
/// - Live stats: time, walked distance, current pace, average pace
/// - German voice navigation via flutter_tts at 300m / 100m / "now"
/// - Wakelock so the screen stays on while tracking
class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({
    super.key,
    required this.route,
    this.startImmediately = false,
  });

  final Map<String, dynamic> route;
  final bool startImmediately;

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen>
    with WidgetsBindingObserver {
  static const Distance _distance = Distance();
  static const Duration _minimumSavedRunDuration = Duration(minutes: 5);

  final MapController _mapController = MapController();

  // Route data, decoded once in initState.
  late final List<LatLng> _planned;
  late final List<_NavStep> _steps;

  // Live state.
  StreamSubscription<Position>? _posSub;
  Position? _lastPos;
  final List<LatLng> _recorded = [];
  final List<int> _recordedPointTimestamps = [];
  double _recordedMeters = 0;
  RunElevationAccumulator _elevation = RunElevationAccumulator();
  double _maxSpeedKmh = 0;
  bool _tracking = false;
  bool _paused = false;
  DateTime? _segmentStartedAt;
  Duration _elapsedAccum = Duration.zero;
  Timer? _ticker;
  bool _autoFollow = true;

  // Navigation cursor.
  int _nextStepIdx = 0;
  final Set<int> _announced300 = {};
  final Set<int> _announced100 = {};
  final Set<int> _announcedNow = {};
  bool _arrivedAnnounced = false;
  String? _activeInstruction;
  double? _activeInstructionDistance;

  // Voice / TTS.
  FlutterTts? _tts;
  bool _voiceEnabled = true;
  AppLocalizations? _l10n;
  DateTime? _lastLivePublish;
  double _lastPublishedMeters = -1;
  DateTime? _runStartedAt;
  bool _shareLive = false, _starting = false, _finishing = false;
  bool? _liveSyncOk;
  int _gpsGeneration = 0;
  late final LiveRunPublisher<LiveRunUpdate> _livePublisher;

  // GPS readiness.
  bool _hasFix = false;
  bool _mapReady = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _livePublisher = LiveRunPublisher(
      send: SocialService.instance.publishLiveRun,
      clear: SocialService.instance.clearActiveRun,
      onResult: (success) {
        if (mounted) setState(() => _liveSyncOk = success);
      },
    );
    _planned = _decodePoints(widget.route['points']);
    _steps = _decodeSteps(widget.route['steps']);
    _voiceEnabled = ProgressStore.workoutVoiceEnabled;
    _initWakelock();
    _initTts();
    _startGpsStream();
    // After first frame, fit the camera to the full planned route so the
    // user immediately sees the entire path they will run. Once they press
    // "Start", the auto-follow kicks in and zooms back onto their position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitToPlannedRoute();
      if (widget.startImmediately) {
        unawaited(_start(askToShare: false));
      }
    });
  }

  void _fitToPlannedRoute() {
    if (!_mapReady || _planned.length < 2) return;
    final bounds = LatLngBounds.fromPoints(_planned);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          left: 40,
          right: 40,
          top: 110,
          bottom: 220,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = context.l10n;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsGeneration++;
    _posSub?.cancel();
    _ticker?.cancel();
    _tts?.stop();
    WakelockPlus.disable().ignore();
    _livePublisher.stop().ignore();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app goes to background, keep the geolocator alive but stop
    // re-rendering. Wakelock is released by the OS for backgrounded apps.
    if (state == AppLifecycleState.resumed && _tracking && !_paused) {
      WakelockPlus.enable().ignore();
    }
  }

  // ─── Decode helpers ─────────────────────────────────────────────────────

  List<LatLng> _decodePoints(Object? raw) {
    if (raw is! List) return const [];
    final out = <LatLng>[];
    for (final entry in raw) {
      if (entry is List && entry.length >= 2) {
        final lat = (entry[0] as num?)?.toDouble();
        final lon = (entry[1] as num?)?.toDouble();
        if (lat != null && lon != null) out.add(LatLng(lat, lon));
      }
    }
    return out;
  }

  List<_NavStep> _decodeSteps(Object? raw) {
    if (raw is! List) return const [];
    final out = <_NavStep>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final instruction = (entry['instruction'] ?? '').toString().trim();
      if (instruction.isEmpty) continue;
      final dist = (entry['distanceMeters'] as num?)?.toDouble() ?? 0.0;
      final endIdx = (entry['endIndex'] as num?)?.toInt() ?? 0;
      if (_planned.isEmpty) continue;
      final clampedIdx = endIdx.clamp(0, _planned.length - 1);
      out.add(
        _NavStep(
          instruction: instruction,
          distanceMeters: dist,
          endPoint: _planned[clampedIdx],
        ),
      );
    }
    return out;
  }

  // ─── Setup ──────────────────────────────────────────────────────────────

  Future<void> _initWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Desktop platforms may not support it – not critical.
    }
  }

  Future<void> _initTts() async {
    try {
      final tts = FlutterTts();
      await WorkoutTtsService.configure(
        tts,
        appLocaleCode: ProgressStore.appLocaleCode,
        voiceGender: WorkoutTtsService.parseGender(
          ProgressStore.workoutVoiceGender,
        ),
        speechRate: 0.5,
      );
      _tts = tts;
    } catch (_) {
      _tts = null;
    }
  }

  Future<void> _startGpsStream() async {
    final generation = ++_gpsGeneration;
    await _posSub?.cancel();
    _posSub = null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted || generation != _gpsGeneration) return;
      if (!serviceEnabled) {
        setState(() => _gpsError = context.l10n.run_gpsOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted || generation != _gpsGeneration) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _gpsError = context.l10n.run_gpsDenied);
        return;
      }

      final LocationSettings settings;
      if (Platform.isAndroid && _tracking) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
          intervalDuration: const Duration(seconds: 2),
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: 'Kaizen',
            notificationText: ProgressStore.useGerman
                ? 'Laufaufzeichnung aktiv. In Kaizen kannst du sie beenden.'
                : 'Run recording active. Open Kaizen to stop.',
            enableWakeLock: true,
          ),
        );
      } else if (Platform.isIOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.fitness,
          distanceFilter: 2,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: _tracking,
          showBackgroundLocationIndicator: _tracking,
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        );
      }
      _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        _onPosition,
        onError: (Object e) {
          if (mounted) {
            setState(() => _gpsError = context.l10n.run_gpsError('$e'));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _gpsError = context.l10n.run_gpsStartFailed('$e'));
      }
    }
  }

  // ─── Position pipeline ──────────────────────────────────────────────────

  void _onPosition(Position pos) {
    if (!mounted) return;
    if (!pos.latitude.isFinite ||
        !pos.longitude.isFinite ||
        pos.latitude.abs() > 90 ||
        pos.longitude.abs() > 180 ||
        !pos.accuracy.isFinite ||
        pos.accuracy > 80 ||
        (_lastPos != null && pos.timestamp.isBefore(_lastPos!.timestamp))) {
      return;
    }
    _lastPos = pos;
    final here = LatLng(pos.latitude, pos.longitude);

    if (!_hasFix) {
      setState(() => _hasFix = true);
      // Center camera on first fix.
      if (_mapReady) _mapController.move(here, 17);
    }

    if (_tracking && !_paused) {
      // Add to recorded path with simple noise filter.
      final previousCount = _recorded.length;
      if (_recorded.isEmpty) {
        _recorded.add(here);
        _recordedPointTimestamps.add(pos.timestamp.millisecondsSinceEpoch);
      } else {
        final prev = _recorded.last;
        final d = _distance.as(LengthUnit.Meter, prev, here);
        if (d >= 3.0 && d < 80.0) {
          _recorded.add(here);
          _recordedPointTimestamps.add(pos.timestamp.millisecondsSinceEpoch);
          _recordedMeters += d;
        } else if (d >= 80.0) {
          // Likely a GPS jump; still record but don't add to distance.
          _recorded.add(here);
          _recordedPointTimestamps.add(pos.timestamp.millisecondsSinceEpoch);
        }
      }

      if (_recorded.length > previousCount) {
        _elevation.add(pos.altitude, pos.altitudeAccuracy);
        if (pos.speed.isFinite &&
            pos.speed >= 0 &&
            pos.speed <= 70 &&
            pos.speedAccuracy.isFinite &&
            pos.speedAccuracy >= 0 &&
            pos.speedAccuracy <= 3) {
          _maxSpeedKmh = math.max(_maxSpeedKmh, pos.speed * 3.6);
        }
      }
      _updateNavigation(here);
    }

    if (_autoFollow && _mapReady) {
      _mapController.move(here, _mapController.camera.zoom);
    }

    _maybePublishLiveRun(pos);
    setState(() {});
  }

  List<List<double>> _plannedPointsPayload() {
    return _planned
        .map((p) => [p.latitude, p.longitude])
        .toList(growable: false);
  }

  List<List<double>> _recordedPointsPayload() {
    return _recorded
        .map((p) => [p.latitude, p.longitude])
        .toList(growable: false);
  }

  double? _currentPaceFromPosition(Position pos) {
    if (pos.speed <= 0.5) return null;
    final secPerKm = 1000 / pos.speed;
    if (secPerKm > 60 * 30) return null;
    return secPerKm;
  }

  double? _avgPaceSecPerKm() {
    final elapsed =
        _elapsedAccum +
        (_segmentStartedAt == null
            ? Duration.zero
            : DateTime.now().difference(_segmentStartedAt!));
    if (_recordedMeters < 20 || elapsed.inSeconds <= 0) return null;
    return elapsed.inSeconds / (_recordedMeters / 1000.0);
  }

  void _maybePublishLiveRun(Position pos) {
    if (!_tracking || !_shareLive || _runStartedAt == null) return;
    final now = DateTime.now();
    final dueTime =
        _lastLivePublish == null ||
        now.difference(_lastLivePublish!) >= const Duration(seconds: 5);
    final dueDistance = (_recordedMeters - _lastPublishedMeters).abs() >= 20;
    if (!dueTime && !dueDistance) return;

    _lastLivePublish = now;
    _lastPublishedMeters = _recordedMeters;
    _livePublisher.update(
      LiveRunUpdate(
        routeId: widget.route['id']?.toString() ?? '',
        routeName: widget.route['name']?.toString() ?? 'Run',
        latitude: pos.latitude,
        longitude: pos.longitude,
        distanceMeters: _recordedMeters,
        currentPaceSecPerKm: _paused ? null : _currentPaceFromPosition(pos),
        avgPaceSecPerKm: _avgPaceSecPerKm(),
        recordedPoints: _recordedPointsPayload(),
        recordedPointTimestamps: List<int>.unmodifiable(
          _recordedPointTimestamps,
        ),
        plannedPoints: _plannedPointsPayload(),
        startedAt: _runStartedAt!,
        positionUpdatedAt: pos.timestamp,
        paused: _paused,
      ),
    );
  }

  void _updateNavigation(LatLng here) {
    if (_steps.isEmpty) return;
    final l10n = _l10n;
    if (l10n == null) return;

    // Skip past any steps the user has already crossed.
    while (_nextStepIdx < _steps.length) {
      final step = _steps[_nextStepIdx];
      final d = _distance.as(LengthUnit.Meter, here, step.endPoint);

      if (d <= 25) {
        // Treat as reached: announce the maneuver itself if not yet.
        if (!_announcedNow.contains(_nextStepIdx)) {
          _announcedNow.add(_nextStepIdx);
          _speak(step.instruction);
          _activeInstruction = step.instruction;
          _activeInstructionDistance = 0;
        }
        _nextStepIdx++;
        continue;
      }

      // Pre-announcements.
      if (d <= 100 && !_announced100.contains(_nextStepIdx)) {
        _announced100.add(_nextStepIdx);
        _speak(l10n.run_ttsIn100m(step.instruction));
      } else if (d <= 300 && !_announced300.contains(_nextStepIdx)) {
        _announced300.add(_nextStepIdx);
        // Only pre-announce at 300m if the step is long enough to make sense.
        if (step.distanceMeters >= 150) {
          _speak(l10n.run_ttsIn300m(step.instruction));
        }
      }

      _activeInstruction = step.instruction;
      _activeInstructionDistance = d;
      break;
    }

    // Arrival check.
    if (_planned.isNotEmpty && !_arrivedAnnounced) {
      final toGoal = _distance.as(LengthUnit.Meter, here, _planned.last);
      if (toGoal <= 25) {
        _arrivedAnnounced = true;
        _speak(l10n.run_ttsGoalReached);
        _activeInstruction = l10n.run_goalReached;
        _activeInstructionDistance = 0;
      }
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // TTS errors must never crash the run.
    }
  }

  // ─── Controls ───────────────────────────────────────────────────────────

  Future<void> _start({bool askToShare = true}) async {
    if (_tracking || _starting || _finishing) return;
    _starting = true;
    bool? share = false;
    if (askToShare &&
        SocialService.instance.cloudEnabled &&
        SocialService.instance.friends.isNotEmpty) {
      share = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            ProgressStore.useGerman
                ? 'Lauf live teilen?'
                : 'Share this run live?',
          ),
          content: Text(
            ProgressStore.useGerman
                ? 'Deine bestätigten Freunde sehen während dieses Laufs deine Position, Strecke und dein Tempo. Beim Beenden endet die Freigabe.'
                : 'Your accepted friends can see your location, route and pace during this run. Sharing ends when you stop.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                ProgressStore.useGerman ? 'Nur aufzeichnen' : 'Record only',
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                ProgressStore.useGerman
                    ? 'Live teilen & starten'
                    : 'Share live & start',
              ),
            ),
          ],
        ),
      );
    }
    _starting = false;
    if (!mounted || share == null) return;
    _shareLive = share;
    _liveSyncOk = null;
    _lastLivePublish = null;
    _lastPublishedMeters = -1;
    _runStartedAt = DateTime.now();
    if (_shareLive) _livePublisher.start();
    setState(() {
      _tracking = true;
      _paused = false;
      _segmentStartedAt = DateTime.now();
      _elapsedAccum = Duration.zero;
      _recorded.clear();
      _recordedPointTimestamps.clear();
      _elevation = RunElevationAccumulator();
      _maxSpeedKmh = 0;
      _recordedMeters = 0;
      _nextStepIdx = 0;
      _announced300.clear();
      _announced100.clear();
      _announcedNow.clear();
      _arrivedAnnounced = false;
      _activeInstruction = null;
      _activeInstructionDistance = null;
      _autoFollow = true;
    });
    // Zoom from the overview onto the runner so they can see their dot
    // and the next stretch of the route.
    final pos = _lastPos;
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
    } else if (_planned.isNotEmpty) {
      _mapController.move(_planned.first, 17);
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        if (_lastPos != null) _maybePublishLiveRun(_lastPos!);
      }
    });
    _speak(_l10n!.run_ttsStarted);
    // Publish the actual fix immediately, never the route origin or (0,0).
    if (pos != null) _maybePublishLiveRun(pos);
    await _startGpsStream();
  }

  void _pause() {
    if (!_tracking || _paused) return;
    setState(() {
      _paused = true;
      _elevation.resetSegment();
      if (_segmentStartedAt != null) {
        _elapsedAccum += DateTime.now().difference(_segmentStartedAt!);
      }
      _segmentStartedAt = null;
    });
    _lastLivePublish = null;
    if (_lastPos != null) _maybePublishLiveRun(_lastPos!);
    _speak(_l10n!.run_ttsPause);
  }

  void _resume() {
    if (!_tracking || !_paused) return;
    setState(() {
      _paused = false;
      _segmentStartedAt = DateTime.now();
    });
    _lastLivePublish = null;
    if (_lastPos != null) _maybePublishLiveRun(_lastPos!);
    _speak(_l10n!.run_ttsResume);
  }

  Future<void> _confirmStop() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.run_endTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.run_endBody,
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.run_keepRunning,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RunMapStyle.accent(context),
              foregroundColor: RunMapStyle.foreground(context),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.run_end),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (!mounted || _finishing) return;
    final freeRunName = context.l10n.running_freeRunName;
    final wasTracking = _tracking;
    final wasFreeRun =
        (widget.route['id']?.toString().startsWith('free_') ?? false) ||
        ((widget.route['points'] as List?)?.isEmpty ?? true);
    setState(() {
      _finishing = true;
      _tracking = false;
      _paused = false;
      if (_segmentStartedAt != null) {
        _elapsedAccum += DateTime.now().difference(_segmentStartedAt!);
        _segmentStartedAt = null;
      }
    });
    _ticker?.cancel();
    _ticker = null;
    final stoppedSharing = _livePublisher.stop().then(
      (_) => true,
      onError: (_) => false,
    );
    _gpsGeneration++;
    await _posSub?.cancel();
    _posSub = null;
    if (!await stoppedSharing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ProgressStore.useGerman
                  ? 'Offline: Die Live-Anzeige läuft spätestens nach 2 Minuten ohne Update ab.'
                  : 'Offline: live presence expires after 2 minutes without an update.',
            ),
          ),
        );
      }
    }
    await _tts?.stop();

    var xpEarned = 0;
    CalorieBurnResult? burn;
    final runTooShort = wasTracking && _elapsedAccum < _minimumSavedRunDuration;
    final shouldSaveRun = wasTracking && !runTooShort && _recordedMeters > 50;
    Map<String, dynamic>? runRecord;
    if (shouldSaveRun) {
      final durationSeconds = _elapsedAccum.inSeconds.clamp(1, 86400);
      // Persist as a workout event so it shows in calendar / streak.
      // Run XP is distance-based: +1 level per full 5 km.
      xpEarned = (_recordedMeters ~/ 5000).toInt();
      burn = CalorieBurnService.runSession(
        meters: _recordedMeters,
        durationSeconds: durationSeconds,
      );
      final activity = RouteActivity(
        durationSeconds: durationSeconds,
        descentMeters: _elevation.descent,
        maxSpeedKmh: _maxSpeedKmh,
        calories: burn.totalKcal,
        elevationRecorded: _elevation.hasData,
        recordedAt: _runStartedAt ?? DateTime.now(),
      );
      final points = _recordedPointsPayload();
      runRecord = {
        'name': widget.route['name']?.toString() ?? freeRunName,
        'distanceMeters': _recordedMeters,
        'ascentMeters': _elevation.ascent,
        'descentMeters': _elevation.descent,
        'points': points,
        'waypoints': [points.first, points.last],
        'steps': <Map<String, dynamic>>[],
        'activity': activity.toJson(),
      };
      var routeId = widget.route['id']?.toString();
      if (wasFreeRun) {
        routeId = await ProgressStore.saveRunningRoute(
          name: runRecord['name'] as String,
          distanceMeters: _recordedMeters,
          ascentMeters: _elevation.ascent,
          descentMeters: _elevation.descent,
          points: points,
          waypoints: [points.first, points.last],
          activity: activity.toJson(),
        );
      }
      // Persist the full recorded path even when a planned route was followed.
      // A map-image failure must never lose an otherwise completed session.
      final snapshotId = 'run_${DateTime.now().microsecondsSinceEpoch}';
      try {
        await RunSnapshotService.save(
          runRecord,
          id: snapshotId,
          german: ProgressStore.useGerman,
        );
        runRecord['snapshotId'] = snapshotId;
      } catch (_) {
        /* The history preview can regenerate from the saved path. */
      }
      await ProgressStore.applyWorkoutRewards(
        workoutType: 'run',
        runRecord: runRecord,
        runMeters: _recordedMeters,
        caloriesBurned: burn.totalKcal,
        durationSeconds: burn.durationSeconds,
        workoutName: widget.route['name']?.toString(),
        workoutId: routeId,
        calorieBreakdown: CalorieBurnService.breakdownToMaps(burn.breakdown),
      );
    }

    if (!mounted) return;
    final shareWithCommunity = await _showSummary(
      xpEarned: xpEarned,
      burn: burn,
      canShare: shouldSaveRun,
      runTooShort: runTooShort,
    );
    if (!mounted) return;
    if (shareWithCommunity && runRecord != null) {
      await showRunShareSheet(context: context, route: runRecord);
    }
    if (!mounted) return;
    if (shouldSaveRun) {
      AppTabNavigation.returnHome(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showSummary({
    required int xpEarned,
    required bool canShare,
    required bool runTooShort,
    CalorieBurnResult? burn,
  }) async {
    final l10n = context.l10n;
    final distKm = _recordedMeters / 1000.0;
    final elapsed = _elapsedAccum;
    final paceText = _paceText(_recordedMeters, elapsed);
    final metersToNext = 5000 - (_recordedMeters.toInt() % 5000);

    var shareWithCommunity = false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                backgroundColor: AppColors.card,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  l10n.run_finishedTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow(
                      l10n.run_distance,
                      '${distKm.toStringAsFixed(2)} km',
                    ),
                    _summaryRow(l10n.run_time, _formatDuration(elapsed)),
                    if (runTooShort) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: RunMapStyle.accent(
                            context,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: RunMapStyle.accent(
                              context,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          ProgressStore.useGerman
                              ? 'Läufe unter 5 Minuten werden nicht gespeichert.'
                              : 'Runs shorter than 5 minutes are not saved.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    _summaryRow(l10n.run_labelPace, paceText),
                    if (burn != null && burn.totalKcal > 0) ...[
                      _summaryRow(
                        l10n.run_calories,
                        '${burn.totalKcal} ${l10n.analytics_unitKcal}',
                      ),
                      if (burn.breakdown.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final line in burn.breakdown)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    l10n.calendar_calorieBreakdown(
                                      line.label,
                                      '${line.kcal}',
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    _summaryRow(
                      l10n.run_level,
                      xpEarned > 0 ? '+$xpEarned' : '+0',
                    ),
                    if (canShare)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          xpEarned > 0
                              ? l10n.run_levelNextMeters('$metersToNext')
                              : l10n.run_levelEvery5km('$metersToNext'),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    if (canShare) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: shareWithCommunity,
                        onChanged: (value) => setDialogState(
                          () => shareWithCommunity = value ?? false,
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: RunMapStyle.accent(context),
                        title: Text(
                          ProgressStore.useGerman
                              ? 'Aktivität teilen'
                              : 'Share activity',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          ProgressStore.useGerman
                              ? 'Danach Aktivitätsart und Empfänger auswählen.'
                              : 'Choose activity type and recipients next.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: RunMapStyle.accent(context),
                      foregroundColor: RunMapStyle.foreground(context),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(shareWithCommunity),
                    child: Text(l10n.common_close),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Formatting ─────────────────────────────────────────────────────────

  Duration get _liveElapsed {
    var d = _elapsedAccum;
    if (_segmentStartedAt != null) {
      d += DateTime.now().difference(_segmentStartedAt!);
    }
    return d;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  String _paceText(double meters, Duration elapsed) {
    if (meters < 30 || elapsed.inSeconds < 5) return '—';
    final km = meters / 1000.0;
    final paceSecPerKm = elapsed.inSeconds / km;
    final m = (paceSecPerKm ~/ 60).toString();
    final s = (paceSecPerKm.round() % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_tracking,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmStop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildMap()),
              Positioned(top: 8, left: 8, right: 8, child: _buildTopBar()),
              if (_activeInstruction != null && _tracking)
                Positioned(
                  top: 64,
                  left: 12,
                  right: 12,
                  child: _buildInstructionCard(),
                ),
              Positioned(
                right: 12,
                top: 140,
                child: Column(
                  children: [
                    _MapBtn(
                      icon: _autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed,
                      tooltip: _autoFollow
                          ? l10n.run_autoFollowOn
                          : l10n.run_autoFollowOff,
                      onPressed: () =>
                          setState(() => _autoFollow = !_autoFollow),
                    ),
                    const SizedBox(height: 8),
                    _MapBtn(
                      icon: _voiceEnabled ? Icons.volume_up : Icons.volume_off,
                      tooltip: _voiceEnabled
                          ? l10n.run_voiceOn
                          : l10n.run_voiceOff,
                      onPressed: () {
                        setState(() => _voiceEnabled = !_voiceEnabled);
                        if (!_voiceEnabled) _tts?.stop();
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final markers = <Marker>[];
    if (_planned.isNotEmpty) {
      markers.add(
        Marker(
          point: _planned.first,
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: RunWaypointMarker(
            kind: RunWaypointKind.start,
            label: context.l10n.running_pinStart,
          ),
        ),
      );
      if (_planned.length > 1) {
        markers.add(
          Marker(
            point: _planned.last,
            width: 44,
            height: 44,
            alignment: Alignment.topCenter,
            child: RunWaypointMarker(
              kind: RunWaypointKind.finish,
              label: context.l10n.running_pinEnd,
            ),
          ),
        );
      }
    }
    final pos = _lastPos;
    if (pos != null) {
      markers.add(
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 44,
          height: 44,
          child: _LocationDot(heading: pos.heading),
        ),
      );
    }

    final initialCenter = _planned.isNotEmpty
        ? _planned.first
        : (pos != null
              ? LatLng(pos.latitude, pos.longitude)
              : const LatLng(48.137154, 11.576124));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 17,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
          _fitToPlannedRoute();
        },
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _autoFollow) {
            // User panned; disable auto-follow until they tap the button again.
            setState(() => _autoFollow = false);
          }
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'de.jankilic.kaizen',
          maxNativeZoom: 19,
        ),
        if (_planned.length >= 2)
          PolylineLayer(
            polylines: [
              // Outer white halo for contrast on busy map tiles.
              Polyline(
                points: _planned,
                color: Colors.white.withValues(alpha: 0.9),
                strokeWidth: 9,
              ),
              // Main planned-route line (green).
              Polyline(
                points: _planned,
                color: RunMapStyle.route.withValues(alpha: 0.6),
                strokeWidth: 6,
                borderColor: Colors.black.withValues(alpha: 0.35),
                borderStrokeWidth: 1.0,
              ),
            ],
          ),
        if (_recorded.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _recorded,
                color: RunMapStyle.route,
                strokeWidth: 6,
                borderColor: Colors.white.withValues(alpha: 0.9),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        const RunMapAttribution(),
      ],
    );
  }

  Widget _buildTopBar() {
    final l10n = context.l10n;
    return Row(
      children: [
        AppBackButton(
          onPressed: () async {
            if (_tracking) {
              await _confirmStop();
            } else if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Icon(
                  _hasFix ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: _hasFix ? RunMapStyle.ink : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _gpsError ??
                        (_tracking
                            ? (_shareLive
                                  ? (_liveSyncOk == false
                                        ? (ProgressStore.useGerman
                                              ? 'Live-Übertragung unterbrochen'
                                              : 'Live sharing interrupted')
                                        : _liveSyncOk == true
                                        ? (ProgressStore.useGerman
                                              ? 'Live mit Freunden geteilt'
                                              : 'Sharing live with friends')
                                        : (ProgressStore.useGerman
                                              ? 'Live-Verbindung wird aufgebaut …'
                                              : 'Connecting live sharing …'))
                                  : (ProgressStore.useGerman
                                        ? 'Lauf wird privat aufgezeichnet'
                                        : 'Recording run privately'))
                            : null) ??
                        (_hasFix
                            ? (widget.route['name']?.toString() ??
                                  l10n.run_start)
                            : l10n.run_waitingGps),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    final l10n = context.l10n;
    final dist = _activeInstructionDistance;
    String distText;
    if (dist == null) {
      distText = '';
    } else if (dist < 25) {
      distText = l10n.run_distNow;
    } else if (dist < 1000) {
      distText = l10n.run_distInMeters('${dist.round()}');
    } else {
      distText = l10n.run_distInKm((dist / 1000).toStringAsFixed(1));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: RunMapStyle.accent(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RunMapStyle.accent(context).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assistant_navigation,
              color: RunMapStyle.accent(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (distText.isNotEmpty)
                  Text(
                    distText,
                    style: TextStyle(
                      color: RunMapStyle.accent(context),
                      fontFamily: 'RobotoMono',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                Text(
                  _activeInstruction ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final l10n = context.l10n;
    final elapsed = _liveElapsed;
    final paceAvg = _paceText(_recordedMeters, elapsed);
    final currentPace = _currentPaceText();
    final distKm = _recordedMeters / 1000.0;
    final plannedKm = ((widget.route['distanceMeters'] as num?) ?? 0) / 1000.0;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Stat(
                  label: l10n.run_labelTime,
                  value: _formatDuration(elapsed),
                ),
                _Stat(
                  label: l10n.run_labelKm,
                  value: distKm.toStringAsFixed(2),
                  hint: plannedKm > 0
                      ? '/ ${plannedKm.toStringAsFixed(2)}'
                      : null,
                ),
                _Stat(
                  label: l10n.run_labelPace,
                  value: currentPace,
                  hint: paceAvg == '—' ? null : 'Ø $paceAvg',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = context.l10n;
    if (_finishing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_tracking) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: RunMapStyle.accent(context),
          foregroundColor: RunMapStyle.foreground(context),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _hasFix ? () => _start() : null,
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          _hasFix ? l10n.run_start : l10n.run_waitGps,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _paused ? _resume : _pause,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.stroke),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 22,
            ),
            label: Text(
              _paused ? l10n.run_resume : l10n.run_pause,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _confirmStop,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.stop_rounded, size: 22),
            label: Text(
              l10n.run_endButton,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _currentPaceText() {
    final pos = _lastPos;
    if (pos == null || !_tracking || _paused) return '—';
    // geolocator speed is in m/s (0 when stationary). Below 0.4 m/s ≈ standing.
    if (pos.speed.isNaN || pos.speed < 0.4) return '—';
    final paceSecPerKm = 1000 / pos.speed;
    if (paceSecPerKm > 60 * 30) return '—'; // > 30 min/km – ignore.
    final m = (paceSecPerKm ~/ 60).toString();
    final s = (paceSecPerKm.round() % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Helper types & widgets ────────────────────────────────────────────────

class _NavStep {
  _NavStep({
    required this.instruction,
    required this.distanceMeters,
    required this.endPoint,
  });
  final String instruction;
  final double distanceMeters;
  final LatLng endPoint;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontFamily: 'RobotoMono',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card.withValues(alpha: 0.94),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.stroke),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _LocationDot extends StatelessWidget {
  const _LocationDot({required this.heading});

  /// Heading in degrees (0..360). Negative or NaN => unknown.
  final double heading;

  @override
  Widget build(BuildContext context) {
    final hasHeading = !heading.isNaN && heading >= 0;
    final rad = hasHeading ? heading * (math.pi / 180.0) : 0.0;

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RunMapStyle.route.withValues(alpha: 0.18),
            ),
          ),
          if (hasHeading)
            Transform.rotate(
              angle: rad,
              child: CustomPaint(
                size: const Size(44, 44),
                painter: _HeadingConePainter(),
              ),
            ),
          // Solid green dot.
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RunMapStyle.route,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x801E88E5), Color(0x001E88E5)],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.width / 2),
        -math.pi / 2 - math.pi / 6,
        math.pi / 3,
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
