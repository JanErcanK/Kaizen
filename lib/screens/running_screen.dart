import '../widgets/app_back_button.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/progress_store.dart';
import '../services/routing_service.dart';
import '../services/social/social_service.dart';
import '../theme/app_colors.dart';
import '../models/social_models.dart';
import '../widgets/run_share_sheet.dart';
import '../widgets/running_welcome.dart';
import '../widgets/home_edge_swipe_back.dart';
import '../widgets/app_segmented_tabs.dart';
import '../widgets/run_route_visuals.dart';
import 'social/friend_live_run_detail_screen.dart';
import 'run_tracking_screen.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key, this.routeCalculator});

  final Future<RouteResult> Function(List<LatLng>)? routeCalculator;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _routeKey = GlobalKey<_RouteBuilderTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != 0) _routeKey.currentState?._dismissWelcome();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToSavedTab() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return HomeEdgeSwipeBack(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const AppBackButton(),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 58,
          toolbarHeight: 64,
          titleSpacing: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          title: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppSegmentedTabs(
              controller: _tabController,
              accent: RunMapStyle.route,
              softSelection: true,
              labels: [
                ProgressStore.useGerman ? 'Laufen' : 'Run',
                l10n.running_tabSaved,
                l10n.running_tabHistory,
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _RouteBuilderTab(
              key: _routeKey,
              onRouteSaved: _goToSavedTab,
              routeCalculator: widget.routeCalculator,
            ),
            const _SavedRoutesTab(),
            const _RunHistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Build a new route ───────────────────────────────────────────────

class _RouteBuilderTab extends StatefulWidget {
  const _RouteBuilderTab({
    super.key,
    required this.onRouteSaved,
    this.routeCalculator,
  });

  final VoidCallback onRouteSaved;
  final Future<RouteResult> Function(List<LatLng>)? routeCalculator;

  @override
  State<_RouteBuilderTab> createState() => _RouteBuilderTabState();
}

class _RouteBuilderTabState extends State<_RouteBuilderTab> {
  final MapController _mapController = MapController();
  final List<LatLng> _waypoints = [];
  RouteResult? _route;
  bool _welcomeVisible = false;
  bool _welcomeDismissed = false;
  void _dismissWelcome() {
    if (_welcomeDismissed || !mounted) return;
    setState(() {
      _welcomeDismissed = true;
      _welcomeVisible = false;
    });
  }

  bool _loadingRoute = false;
  int _routeRequest = 0;
  bool _locating = false;
  bool _showFriends = false;
  bool _showCommunity = false;
  _RunningMapLayer _mapLayer = _RunningMapLayer.standard;
  RangeValues _communityDistanceKm = const RangeValues(0, 50);
  RangeValues _communityAscentMeters = const RangeValues(0, 1500);
  String? _error;
  LatLng? _userLocation;
  LatLng _initialCenter = const LatLng(48.137154, 11.576124); // Munich fallback

  @override
  void initState() {
    super.initState();
    unawaited(SocialService.instance.refreshFriendsHubNow());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_welcomeDismissed) setState(() => _welcomeVisible = true);
      _tryAutoLocate();
    });
  }

  @override
  void dispose() {
    if (_showFriends) SocialService.instance.setFastLivePolling(false);
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoLocate({bool moveCamera = true}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // 1) Instant: use the cached last-known position so the map snaps to
      //    the user immediately, even before a fresh GPS fix is available.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          final here = LatLng(last.latitude, last.longitude);
          _initialCenter = here;
          setState(() => _userLocation = here);
          if (moveCamera) {
            _mapController.move(here, 15);
          }
        }
      } catch (_) {
        // ignore – we still try the precise fix below
      }

      // 2) Precise: get a fresh high-accuracy fix and re-center if it has
      //    arrived in time. Bounded by a timeout so we don't hang forever.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      _initialCenter = here;
      setState(() => _userLocation = here);
      if (moveCamera) {
        _mapController.move(here, 16);
      }
    } catch (_) {
      // Silent fail – user can still pan/zoom manually.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(LatLng point) {
    _dismissWelcome();
    setState(() {
      _routeRequest++;
      _loadingRoute = false;
      _waypoints.add(point);
      _route = null;
      _error = null;
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      if (index < 0 || index >= _waypoints.length) return;
      _routeRequest++;
      _loadingRoute = false;
      _waypoints.removeAt(index);
      _route = null;
      _error = null;
    });
  }

  void _resetAll() {
    setState(() {
      _routeRequest++;
      _loadingRoute = false;
      _waypoints.clear();
      _route = null;
      _error = null;
    });
  }

  Future<void> _calculateRoute() async {
    if (_waypoints.length < 2) {
      setState(() {
        _error = context.l10n.running_needStartEnd;
      });
      return;
    }
    final request = ++_routeRequest;
    setState(() {
      _loadingRoute = true;
      _error = null;
      _route = null;
    });
    try {
      final result =
          await (widget.routeCalculator ?? RoutingService.getWalkingRoute)(
            List<LatLng>.unmodifiable(_waypoints),
          );
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _route = result;
        _loadingRoute = false;
      });
      _fitBoundsToRoute(result.points);
    } on RoutingException catch (e) {
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _error = e.message;
        _loadingRoute = false;
      });
    } catch (e) {
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _error = context.l10n.running_unexpectedError('$e');
        _loadingRoute = false;
      });
    }
  }

  void _fitBoundsToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.fromLTRB(
          48,
          math.min(280, MediaQuery.sizeOf(context).height * 0.35),
          72,
          48,
        ),
      ),
    );
  }

  String _mapLabel(
    BuildContext context, {
    required String de,
    required String en,
  }) => ProgressStore.useGerman ? de : en;

  bool _matchesCommunityFilter(CommunityRun run) {
    final km = run.distanceMeters / 1000;
    return km >= _communityDistanceKm.start &&
        km <= _communityDistanceKm.end &&
        run.ascentMeters >= _communityAscentMeters.start &&
        run.ascentMeters <= _communityAscentMeters.end;
  }

  void _toggleCommunity() {
    final enable = !_showCommunity;
    setState(() => _showCommunity = enable);
    if (enable) {
      unawaited(SocialService.instance.refreshCommunityRunsNow());
    }
  }

  void _toggleFriends() {
    final enable = !_showFriends;
    setState(() => _showFriends = enable);
    SocialService.instance.setFastLivePolling(enable);
    if (enable) unawaited(SocialService.instance.refreshLiveRunsNow());
  }

  Future<void> _showCommunityFilters() async {
    final filters = await showModalBottomSheet<_CommunityMapFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityMapFiltersSheet(
        distance: _communityDistanceKm,
        ascent: _communityAscentMeters,
      ),
    );
    if (filters == null || !mounted) return;
    setState(() {
      _communityDistanceKm = filters.distance;
      _communityAscentMeters = filters.ascent;
      _showCommunity = true;
    });
    unawaited(SocialService.instance.refreshCommunityRunsNow());
  }

  Future<void> _showMapLayers() async {
    final selected = await showModalBottomSheet<_RunningMapLayer>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MapLayerSheet(selected: _mapLayer),
    );
    if (selected != null && mounted) setState(() => _mapLayer = selected);
  }

  List<Polyline> _liveTrailPolylines(FriendLiveRun run) {
    final points = _routePointsToLatLng(run.recordedPoints);
    if (points.length < 2) return const [];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final runStartMs = run.startedAt.millisecondsSinceEpoch;
    final elapsedMs = math.max(1, nowMs - runStartMs);
    final timesMatch = run.recordedPointTimestamps.length == points.length;
    final color = _runColorForUid(run.uid);
    const chunkSize = 8;
    final lines = <Polyline>[];

    for (var start = 0; start < points.length - 1; start += chunkSize) {
      final end = math.min(points.length - 1, start + chunkSize);
      final chunk = points.sublist(start, end + 1);
      final sampleMs = timesMatch
          ? run.recordedPointTimestamps[end]
          : runStartMs + (elapsedMs * end / (points.length - 1)).round();
      final ageFraction = ((nowMs - sampleMs) / elapsedMs)
          .clamp(0.0, 1.0)
          .toDouble();
      final freshness = 1 - ageFraction;
      lines.add(
        Polyline(
          points: chunk,
          color: color.withValues(alpha: 0.22 + freshness * 0.7),
          strokeWidth: 1.2 + freshness * 2.3,
          pattern: _dashedLiveTrailPattern,
        ),
      );
    }
    return lines;
  }

  Future<void> _showCommunityRunDetails(CommunityRun run) async {
    final isGerman = ProgressStore.useGerman;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          run.routeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.displayName,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                RunSnapshotPreview(
                  mapTiles: true,
                  route: {
                    'name': run.routeName,
                    'points': run.points,
                    'distanceMeters': run.distanceMeters,
                    'ascentMeters': run.ascentMeters,
                    if (run.activity != null)
                      'activity': run.activity!.toJson(),
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  '${run.activity?.type.label(isGerman) ?? 'Route'} · ${(run.distanceMeters / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(run.createdAt),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (run.uid == SocialService.instance.currentUid)
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await SocialService.instance.deleteCommunityRun(run.id);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isGerman
                              ? 'Lauf konnte nicht entfernt werden.'
                              : 'Could not remove the run.',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(isGerman ? 'Teilen beenden' : 'Remove share'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRoute() async {
    final route = _route;
    if (route == null) return;
    final name = await _askForName(context);
    if (name == null) return;

    final points = route.points
        .map((p) => [p.latitude, p.longitude])
        .toList(growable: false);
    final wps = _waypoints
        .map((p) => [p.latitude, p.longitude])
        .toList(growable: false);
    final steps = route.steps
        .map(
          (s) => <String, dynamic>{
            'instruction': s.instruction,
            'distanceMeters': s.distanceMeters,
            'endIndex': s.endIndex,
          },
        )
        .toList(growable: false);

    await ProgressStore.saveRunningRoute(
      name: name,
      distanceMeters: route.distanceMeters,
      ascentMeters: route.ascentMeters,
      descentMeters: route.descentMeters,
      points: points,
      waypoints: wps,
      steps: steps,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.card,
        content: Text(
          context.l10n.running_routeSaved(name),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
    _resetAll();
    widget.onRouteSaved();
  }

  Future<String?> _askForName(BuildContext context) async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final controller = TextEditingController(
      text: l10n.running_defaultRouteName('${now.day}.${now.month}.'),
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.running_saveRouteTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.running_routeNameLabel,
              labelStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.common_cancel,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: RunMapStyle.accent(context),
                foregroundColor: RunMapStyle.foreground(context),
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop(name);
              },
              child: Text(l10n.running_save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildMap()),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          height: math.min(340, MediaQuery.sizeOf(context).height * .40),
          child: RunningWelcome(
            visible: _welcomeVisible,
            german: ProgressStore.useGerman,
          ),
        ),
        Positioned(
          top: 12,
          bottom: 106,
          left: 12,
          right: 72,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Listener(
                onPointerDown: (_) => _dismissWelcome(),
                child: SingleChildScrollView(child: _buildTopPanel()),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          bottom: 106,
          child: Align(
            alignment: const Alignment(1, .15),
            child: Listener(
              onPointerDown: (_) => _dismissWelcome(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapIconButton(
                      icon: Icons.person_pin_circle_outlined,
                      tooltip: _mapLabel(context, de: 'Freunde', en: 'Friends'),
                      selected: _showFriends,
                      onPressed: _toggleFriends,
                    ),
                    const SizedBox(height: 6),
                    _MapIconButton(
                      icon: Icons.groups_2_outlined,
                      tooltip: _mapLabel(
                        context,
                        de: 'Community',
                        en: 'Community',
                      ),
                      selected: _showCommunity,
                      onPressed: _toggleCommunity,
                      onLongPress: _showCommunityFilters,
                    ),
                    const SizedBox(height: 6),
                    _MapIconButton(
                      icon: Icons.layers_outlined,
                      tooltip: _mapLabel(
                        context,
                        de: 'Kartenebenen',
                        en: 'Map layers',
                      ),
                      onPressed: _showMapLayers,
                    ),
                    const SizedBox(height: 6),
                    _MapIconButton(
                      icon: _locating ? Icons.hourglass_top : Icons.my_location,
                      tooltip: context.l10n.running_myLocation,
                      onPressed: _locating ? null : () => _tryAutoLocate(),
                    ),
                    if (_waypoints.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _MapIconButton(
                        icon: Icons.undo_rounded,
                        tooltip: context.l10n.running_removeLastPoint,
                        onPressed: () => _removeWaypoint(_waypoints.length - 1),
                      ),
                      const SizedBox(height: 6),
                      _MapIconButton(
                        icon: Icons.delete_outline,
                        tooltip: context.l10n.running_reset,
                        onPressed: _resetAll,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                key: const Key('running-start'),
                onPressed: _startFreeRun,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB9EE85),
                  foregroundColor: const Color(0xFF172C22),
                  elevation: 5,
                  shadowColor: const Color(0x443A6546),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  ProgressStore.useGerman ? 'Lauf starten' : 'Start run',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_showCommunity)
          Positioned(
            left: 12,
            right: 68,
            bottom: 80,
            child: ValueListenableBuilder<int>(
              valueListenable: SocialService.instance.listenable,
              builder: (context, _, __) {
                final social = SocialService.instance;
                if (social.communityRuns.isNotEmpty &&
                    !social.communityLoadFailed)
                  return const SizedBox.shrink();
                final de = ProgressStore.useGerman;
                final message = social.communityLoading
                    ? (de
                          ? 'Community-Läufe werden geladen …'
                          : 'Loading community runs …')
                    : social.communityAccessDenied
                    ? (de
                          ? 'Firebase verweigert den Zugriff auf Community-Läufe.'
                          : 'Firebase denied access to community runs.')
                    : social.communityLoadFailed
                    ? (de
                          ? 'Community-Läufe konnten nicht geladen werden.'
                          : 'Could not load community runs.')
                    : (de
                          ? 'Noch keine Community-Läufe geteilt.'
                          : 'No community runs have been shared yet.');
                return _MapStatusPill(
                  icon: Icons.groups_2_outlined,
                  text: message,
                  onRetry: social.communityLoadFailed
                      ? () => social.refreshCommunityRunsNow(force: true)
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMap() {
    return ValueListenableBuilder<int>(
      valueListenable: SocialService.instance.listenable,
      builder: (context, _, _) {
        final social = SocialService.instance;
        final liveRuns = _showFriends
            ? social.friendsLiveRuns.where((run) => !run.isStale).toList()
            : const <FriendLiveRun>[];
        final communityRuns = _showCommunity
            ? social.communityRuns.where(_matchesCommunityFilter).toList()
            : const <CommunityRun>[];
        final markers = <Marker>[];
        final polylines = <Polyline>[];

        for (var i = 0; i < _waypoints.length; i++) {
          final isStart = i == 0;
          final isEnd = i == _waypoints.length - 1 && _waypoints.length > 1;
          final kind = isStart
              ? RunWaypointKind.start
              : isEnd
              ? RunWaypointKind.finish
              : RunWaypointKind.via;
          final label = isStart
              ? context.l10n.running_pinStart
              : isEnd
              ? context.l10n.running_pinEnd
              : '$i';
          markers.add(
            Marker(
              point: _waypoints[i],
              width: 44,
              height: 44,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => _removeWaypoint(i),
                child: RunWaypointMarker(
                  key: ValueKey('${_waypoints[i]}-$kind'),
                  kind: kind,
                  label: label,
                ),
              ),
            ),
          );
        }

        for (final run in communityRuns) {
          if (run.points.length < 2) continue;
          final points = _routePointsToLatLng(run.points);
          final color = _runColorForUid(run.uid);
          polylines.add(
            Polyline(
              points: points,
              color: color.withValues(alpha: 0.78),
              strokeWidth: 3.2,
              borderColor: Colors.white.withValues(alpha: 0.8),
              borderStrokeWidth: 1,
            ),
          );
          markers.add(
            Marker(
              point: points.last,
              width: 34,
              height: 34,
              child: GestureDetector(
                onTap: () => _showCommunityRunDetails(run),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    run.displayName.isEmpty
                        ? '?'
                        : run.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        for (final run in liveRuns) {
          polylines.addAll(_liveTrailPolylines(run));
          if (run.plannedPoints.length > 1) {
            polylines.add(
              Polyline(
                points: _routePointsToLatLng(run.plannedPoints),
                color: _runColorForUid(run.uid).withValues(alpha: 0.18),
                strokeWidth: 2,
              ),
            );
          }
          markers.add(
            Marker(
              point: LatLng(run.latitude, run.longitude),
              width: 46,
              height: 46,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FriendLiveRunDetailScreen(run: run),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: _runColorForUid(run.uid),
                    child: Text(
                      run.displayName.isEmpty
                          ? '?'
                          : run.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (_route != null) {
          polylines.add(
            Polyline(
              points: _route!.points,
              color: RunMapStyle.route,
              strokeWidth: 5,
              borderColor: Colors.white.withValues(alpha: 0.9),
              borderStrokeWidth: 2,
            ),
          );
        } else if (_waypoints.length > 1) {
          // Show a live straight-line preview while the user places points.
          // The routed path replaces it once the route calculation completes.
          polylines.add(
            Polyline(
              points: List<LatLng>.unmodifiable(_waypoints),
              color: RunMapStyle.route.withValues(alpha: 0.65),
              strokeWidth: 3,
              pattern: StrokePattern.dashed(segments: const [6, 6]),
              borderColor: Colors.white.withValues(alpha: 0.8),
              borderStrokeWidth: 1,
            ),
          );
        }

        final tileLayer = TileLayer(
          urlTemplate: _mapLayer.tileUrl,
          subdomains: _mapLayer == _RunningMapLayer.terrain
              ? const ['a', 'b', 'c']
              : const [],
          userAgentPackageName: 'de.jankilic.kaizen',
          maxNativeZoom: _mapLayer == _RunningMapLayer.terrain ? 17 : 19,
        );
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
            onTap: (_, point) => _onMapTap(point),
            onPositionChanged: (_, hasGesture) {
              if (hasGesture) _dismissWelcome();
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (_mapLayer == _RunningMapLayer.retro)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(_sepiaMapMatrix),
                child: tileLayer,
              )
            else
              tileLayer,
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RunMapStyle.route,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            RunMapAttribution(source: _mapLayer.attribution),
          ],
        );
      },
    );
  }

  Widget _buildTopPanel() {
    final l10n = context.l10n;
    final route = _route;
    final canSave = route != null && !_loadingRoute;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: RunMapStyle.ink.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _waypoints.isEmpty
                    ? Icons.touch_app_outlined
                    : Icons.route_rounded,
                size: 16,
                color: RunMapStyle.accent(context),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _waypoints.isEmpty
                      ? l10n.running_mapHint
                      : '${_waypoints.length} ${l10n.running_points.toLowerCase()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: route == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(route),
                    padding: const EdgeInsets.only(top: 14),
                    child: RunRouteSummary(route: route),
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_waypoints.isNotEmpty) ...[
            _compactMapAction(
              icon: Icons.alt_route_rounded,
              label: l10n.running_calculateRoute,
              tooltip: l10n.running_calculateRoute,
              prominent: true,
              active: true,
              enabled: _waypoints.length >= 2 && !_loadingRoute,
              onPressed: _calculateRoute,
            ),
            if (canSave) ...[
              const SizedBox(height: 7),
              _compactMapAction(
                icon: Icons.bookmark_add_outlined,
                label: _mapLabel(context, de: 'Speichern', en: 'Save'),
                tooltip: l10n.running_save,
                enabled: true,
                onPressed: _saveRoute,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _compactMapAction({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    bool active = false,
    bool prominent = false,
  }) {
    final background = prominent
        ? RunMapStyle.accent(context)
        : active
        ? RunMapStyle.accent(context).withValues(alpha: 0.10)
        : AppColors.background.withValues(alpha: 0.72);
    final foreground = prominent
        ? (Theme.of(context).brightness == Brightness.dark
              ? RunMapStyle.ink
              : Colors.white)
        : active
        ? RunMapStyle.accent(context)
        : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: prominent ? 44 : 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prominent && _loadingRoute)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 16,
                    color: enabled ? foreground : AppColors.textMuted,
                  ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled ? foreground : AppColors.textMuted,
                      fontSize: prominent ? 14 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startFreeRun() {
    _dismissWelcome();
    final plannedRoute = _route;
    final now = DateTime.now();
    final date = '${now.day}.${now.month}.';

    // Keep the planned route in this builder while tracking. It remains
    // available to save when the user returns from the run screen.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunTrackingScreen(
          startImmediately: true,
          route: {
            'id': 'free_${DateTime.now().microsecondsSinceEpoch}',
            'name': plannedRoute == null
                ? context.l10n.running_freeRunName
                : context.l10n.running_defaultRouteName(date),
            'distanceMeters': plannedRoute?.distanceMeters ?? 0.0,
            'ascentMeters': plannedRoute?.ascentMeters ?? 0.0,
            'descentMeters': plannedRoute?.descentMeters ?? 0.0,
            'points':
                plannedRoute?.points
                    .map((p) => [p.latitude, p.longitude])
                    .toList(growable: false) ??
                const <List<double>>[],
            'waypoints': _waypoints
                .map((p) => [p.latitude, p.longitude])
                .toList(growable: false),
            'steps':
                plannedRoute?.steps
                    .map(
                      (step) => <String, dynamic>{
                        'instruction': step.instruction,
                        'distanceMeters': step.distanceMeters,
                        'endIndex': step.endIndex,
                      },
                    )
                    .toList(growable: false) ??
                const <Map<String, dynamic>>[],
          },
        ),
      ),
    );
  }
}

enum _RunningMapLayer { standard, terrain, retro }

extension on _RunningMapLayer {
  String get tileUrl => switch (this) {
    _RunningMapLayer.standard =>
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    _RunningMapLayer.terrain =>
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    _RunningMapLayer.retro => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  };

  String get attribution => switch (this) {
    _RunningMapLayer.standard ||
    _RunningMapLayer.retro => '© OpenStreetMap contributors',
    _RunningMapLayer.terrain =>
      'Kartendaten © OpenStreetMap · SRTM | Kartendarstellung © OpenTopoMap (CC-BY-SA)',
  };

  String label(bool german) => switch (this) {
    _RunningMapLayer.standard => german ? 'Klassisch' : 'Standard',
    _RunningMapLayer.terrain => german ? 'Topografisch' : 'Terrain',
    _RunningMapLayer.retro => 'Retro',
  };

  IconData get icon => switch (this) {
    _RunningMapLayer.standard => Icons.map_outlined,
    _RunningMapLayer.terrain => Icons.terrain_rounded,
    _RunningMapLayer.retro => Icons.history_rounded,
  };
}

const List<double> _sepiaMapMatrix = [
  0.393,
  0.769,
  0.189,
  0,
  0,
  0.349,
  0.686,
  0.168,
  0,
  0,
  0.272,
  0.534,
  0.131,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

final StrokePattern _dashedLiveTrailPattern = StrokePattern.dashed(
  segments: const [5.0, 4.0],
);

List<LatLng> _routePointsToLatLng(List<List<double>> points) => points
    .where(
      (point) =>
          point.length >= 2 &&
          point[0].isFinite &&
          point[1].isFinite &&
          point[0].abs() <= 90 &&
          point[1].abs() <= 180,
    )
    .map((point) => LatLng(point[0], point[1]))
    .toList(growable: false);

Color _runColorForUid(String uid) {
  var hash = 0;
  for (final unit in uid.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.55, 0.52).toColor();
}

class _CommunityMapFilters {
  const _CommunityMapFilters({required this.distance, required this.ascent});

  final RangeValues distance;
  final RangeValues ascent;
}

class _CommunityMapFiltersSheet extends StatefulWidget {
  const _CommunityMapFiltersSheet({
    required this.distance,
    required this.ascent,
  });

  final RangeValues distance;
  final RangeValues ascent;

  @override
  State<_CommunityMapFiltersSheet> createState() =>
      _CommunityMapFiltersSheetState();
}

class _CommunityMapFiltersSheetState extends State<_CommunityMapFiltersSheet> {
  late RangeValues _distance = widget.distance;
  late RangeValues _ascent = widget.ascent;

  @override
  Widget build(BuildContext context) {
    final german = ProgressStore.useGerman;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              german ? 'Community-Läufe filtern' : 'Filter community runs',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              german
                  ? 'Nur Läufe im gewählten Bereich werden auf der Karte angezeigt.'
                  : 'Only runs in the selected ranges appear on the map.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            _rangeHeading(
              german ? 'Distanz' : 'Distance',
              '${_distance.start.round()}–${_distance.end.round()} km',
            ),
            RangeSlider(
              values: _distance,
              min: 0,
              max: 50,
              divisions: 50,
              activeColor: RunMapStyle.accent(context),
              labels: RangeLabels(
                '${_distance.start.round()} km',
                '${_distance.end.round()} km',
              ),
              onChanged: (value) => setState(() => _distance = value),
            ),
            const SizedBox(height: 8),
            _rangeHeading(
              german ? 'Höhenmeter' : 'Elevation gain',
              '${_ascent.start.round()}–${_ascent.end.round()} m',
            ),
            RangeSlider(
              values: _ascent,
              min: 0,
              max: 1500,
              divisions: 30,
              activeColor: RunMapStyle.accent(context),
              labels: RangeLabels(
                '${_ascent.start.round()} m',
                '${_ascent.end.round()} m',
              ),
              onChanged: (value) => setState(() => _ascent = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _distance = const RangeValues(0, 50);
                    _ascent = const RangeValues(0, 1500);
                  }),
                  child: Text(german ? 'Zurücksetzen' : 'Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    _CommunityMapFilters(distance: _distance, ascent: _ascent),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: RunMapStyle.accent(context),
                    foregroundColor: RunMapStyle.foreground(context),
                  ),
                  child: Text(german ? 'Anwenden' : 'Apply filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeHeading(String title, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: RunMapStyle.accent(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _MapLayerSheet extends StatelessWidget {
  const _MapLayerSheet({required this.selected});

  final _RunningMapLayer selected;

  @override
  Widget build(BuildContext context) {
    final german = ProgressStore.useGerman;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            for (final layer in _RunningMapLayer.values)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(layer.icon, color: RunMapStyle.accent(context)),
                  title: Text(
                    layer.label(german),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: layer == _RunningMapLayer.retro
                      ? Text(
                          german
                              ? 'Warme Vintage-Farbgebung'
                              : 'Warm vintage colors',
                        )
                      : null,
                  trailing: selected == layer
                      ? Icon(
                          Icons.check_circle,
                          color: RunMapStyle.accent(context),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(layer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.icon, required this.text, this.onRetry});
  final VoidCallback? onRetry;

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.card.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.stroke),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: RunMapStyle.accent(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
        ),
        if (onRetry != null)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            tooltip: ProgressStore.useGerman ? 'Erneut versuchen' : 'Retry',
          ),
      ],
    ),
  );
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? RunMapStyle.accent(context).withValues(alpha: 0.12)
            : AppColors.card.withValues(alpha: 0.94),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.stroke),
        ),
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? RunMapStyle.accent(context)
                  : enabled
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab 2: Saved routes ────────────────────────────────────────────────────

class _SavedRoutesTab extends StatelessWidget {
  const _SavedRoutesTab();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final routes = ProgressStore.runningRoutes.reversed.toList();
        if (routes.isEmpty) {
          return _buildEmpty(context);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: routes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _SavedRouteCard(route: routes[index]);
          },
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_run,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.running_noRoutes,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.running_noRoutesHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRunPace(double meters, int durationSeconds) {
  if (meters <= 0 || durationSeconds <= 0) return '—';
  final km = meters / 1000.0;
  final paceSecPerKm = durationSeconds / km;
  final m = (paceSecPerKm ~/ 60).toString();
  final s = (paceSecPerKm.round() % 60).toString().padLeft(2, '0');
  return '$m:$s /km';
}

String _formatRunDuration(int durationSeconds) {
  if (durationSeconds <= 0) return '—';
  final d = Duration(seconds: durationSeconds);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _monthYearLabel(AppLocalizations l10n, DateTime date) {
  final month = switch (date.month) {
    1 => l10n.month_january,
    2 => l10n.month_february,
    3 => l10n.month_march,
    4 => l10n.month_april,
    5 => l10n.month_may,
    6 => l10n.month_june,
    7 => l10n.month_july,
    8 => l10n.month_august,
    9 => l10n.month_september,
    10 => l10n.month_october,
    11 => l10n.month_november,
    12 => l10n.month_december,
    _ => '',
  };
  return '$month ${date.year}';
}

// ─── Tab 3: Run history ─────────────────────────────────────────────────────

class _RunHistoryTab extends StatelessWidget {
  const _RunHistoryTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return ValueListenableBuilder(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final runs = ProgressStore.runEvents;
        final now = DateTime.now();
        final summary = ProgressStore.runSummaryForMonth(now);
        final avgPace = _formatRunPace(summary.meters, summary.durationSeconds);
        final monthKm = (summary.meters / 1000.0).toStringAsFixed(
          summary.meters >= 10000 ? 1 : 2,
        );

        if (runs.isEmpty) {
          return Column(
            children: [
              _RunHistorySummaryCard(
                monthLabel: _monthYearLabel(l10n, now),
                kmLine: l10n.running_historyMonthKm(monthKm),
                paceLine: l10n.running_historyMonthAvgPace(avgPace),
              ),
              Expanded(child: _buildEmpty(context)),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: runs.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 12 : 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _RunHistorySummaryCard(
                monthLabel: _monthYearLabel(l10n, now),
                kmLine: l10n.running_historyMonthKm(monthKm),
                paceLine: l10n.running_historyMonthAvgPace(avgPace),
              );
            }
            return _RunHistoryCard(run: runs[index - 1], locale: locale);
          },
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 56,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.running_historyEmpty,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.running_historyEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunHistorySummaryCard extends StatelessWidget {
  const _RunHistorySummaryCard({
    required this.monthLabel,
    required this.kmLine,
    required this.paceLine,
  });

  final String monthLabel;
  final String kmLine;
  final String paceLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kmLine,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            paceLine,
            style: TextStyle(
              color: RunMapStyle.accent(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}

class _RunHistoryCard extends StatelessWidget {
  const _RunHistoryCard({required this.run, required this.locale});

  final Map<String, dynamic> run;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recordedAt = DateTime.tryParse(run['recordedAt']?.toString() ?? '');
    final meters = (run['runMeters'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (run['durationSeconds'] as num?)?.round() ?? 0;
    final name = run['workoutName']?.toString().trim();
    final title = (name == null || name.isEmpty)
        ? l10n.running_historyUntitledRun
        : name;
    final dateText = recordedAt == null
        ? '—'
        : DateFormat.yMMMd(locale).add_Hm().format(recordedAt);
    final distKm = (meters / 1000.0).toStringAsFixed(meters >= 10000 ? 1 : 2);
    final pace = _formatRunPace(meters, durationSeconds);
    final duration = _formatRunDuration(durationSeconds);
    final record = run['runRecord'] is Map
        ? Map<String, dynamic>.from(run['runRecord'] as Map)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                dateText,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (record != null) ...[
            GestureDetector(
              onTap: () => showRunShareSheet(context: context, route: record),
              child: RunSnapshotPreview(route: record),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: RunMapStyle.accent(context),
                ),
                onPressed: () =>
                    showRunShareSheet(context: context, route: record),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.social_shareAction),
              ),
            ),
          ],
          Row(
            children: [
              _RunHistoryStat(
                label: l10n.running_distance,
                value: '$distKm km',
              ),
              const SizedBox(width: 16),
              _RunHistoryStat(label: l10n.run_labelPace, value: pace),
              const SizedBox(width: 16),
              _RunHistoryStat(label: l10n.run_time, value: duration),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunHistoryStat extends StatelessWidget {
  const _RunHistoryStat({required this.label, required this.value});

  final String label;
  final String value;

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
              letterSpacing: 0.6,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.route});

  final Map<String, dynamic> route;

  List<LatLng> _decodePoints() {
    final raw = route['points'];
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

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.running_deleteRouteTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.running_deleteRouteBody(route['name'].toString()),
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ProgressStore.deleteRunningRoute(route['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _decodePoints();
    final distanceKm = ((route['distanceMeters'] as num?) ?? 0) / 1000.0;
    final ascent = ((route['ascentMeters'] as num?) ?? 0).round();
    final descent = ((route['descentMeters'] as num?) ?? 0).round();
    final name = route['name']?.toString() ?? 'Route';

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _RouteDetailScreen(route: route),
            ),
          ),
          onLongPress: () => _confirmDelete(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: points.isEmpty
                        ? const SizedBox.shrink()
                        : CustomPaint(
                            painter: _MiniRoutePainter(
                              points: points,
                              color: RunMapStyle.accent(context),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm.toStringAsFixed(2)} km',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$ascent / -$descent m',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(route['createdAt']?.toString()),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}

class _MiniRoutePainter extends CustomPainter {
  _MiniRoutePainter({required this.points, required this.color});

  final List<LatLng> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    const padding = 6.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    final spanLat = math.max(maxLat - minLat, 1e-6);
    final spanLon = math.max(maxLon - minLon, 1e-6);
    final scale = math.min(w / spanLon, h / spanLat);
    final offsetX = padding + (w - spanLon * scale) / 2;
    final offsetY = padding + (h - spanLat * scale) / 2;

    Offset project(LatLng p) {
      final x = offsetX + (p.longitude - minLon) * scale;
      // Flip Y so north is up.
      final y = offsetY + (maxLat - p.latitude) * scale;
      return Offset(x, y);
    }

    final path = Path()
      ..moveTo(project(points.first).dx, project(points.first).dy);
    for (var i = 1; i < points.length; i++) {
      final pt = project(points[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;
    canvas.drawPath(path, stroke);

    // Start dot (green) and end dot (red) for quick orientation.
    final startPaint = Paint()..color = RunMapStyle.ink;
    final endPaint = Paint()..color = RunMapStyle.finish;
    canvas.drawCircle(project(points.first), 2.5, startPaint);
    canvas.drawCircle(project(points.last), 2.5, endPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

// ─── Saved route detail screen ──────────────────────────────────────────────

class _RouteDetailScreen extends StatefulWidget {
  const _RouteDetailScreen({required this.route});
  final Map<String, dynamic> route;

  @override
  State<_RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<_RouteDetailScreen> {
  final MapController _mapController = MapController();
  late final List<LatLng> _points;

  @override
  void initState() {
    super.initState();
    _points = _decode(widget.route['points']);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
  }

  List<LatLng> _decode(Object? raw) {
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

  void _fit() {
    if (_points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _rename() async {
    final l10n = context.l10n;
    final ctrl = TextEditingController(
      text: widget.route['name']?.toString() ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.running_renameTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RunMapStyle.accent(context),
              foregroundColor: RunMapStyle.foreground(context),
            ),
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: Text(l10n.common_ok),
          ),
        ],
      ),
    );
    if (name == null) return;
    await ProgressStore.renameRunningRoute(
      routeId: widget.route['id'].toString(),
      newName: name,
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.running_deleteRouteTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.running_deleteConfirmBody,
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.common_cancel,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ProgressStore.deleteRunningRoute(widget.route['id'].toString());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ProgressStore.listenable(),
      builder: (context, _, _) {
        final l10n = context.l10n;
        final current =
            ProgressStore.runningRouteById(widget.route['id'].toString()) ??
            widget.route;
        final distanceKm = ((current['distanceMeters'] as num?) ?? 0) / 1000.0;
        final ascent = ((current['ascentMeters'] as num?) ?? 0).round();
        final descent = ((current['descentMeters'] as num?) ?? 0).round();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(),
            leadingWidth: 44,
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            title: Text(
              current['name']?.toString() ?? 'Route',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: l10n.social_shareAction,
                onPressed: () => showRunShareSheet(
                  context: context,
                  route: Map<String, dynamic>.from(current),
                ),
                icon: Icon(Icons.share_outlined, color: AppColors.textPrimary),
              ),
              IconButton(
                tooltip: l10n.running_renameTitle,
                onPressed: _rename,
                icon: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              ),
              IconButton(
                tooltip: l10n.common_delete,
                onPressed: _delete,
                icon: Icon(Icons.delete_outline, color: AppColors.textPrimary),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _points.isEmpty
                    ? Center(
                        child: Text(
                          l10n.running_noRoutesHint,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _points.first,
                          initialZoom: 14,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'de.jankilic.kaizen',
                            maxNativeZoom: 19,
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _points,
                                color: RunMapStyle.route,
                                strokeWidth: 5,
                                borderColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _points.first,
                                width: 44,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: RunWaypointMarker(
                                  kind: RunWaypointKind.start,
                                  label: l10n.running_pinStart,
                                ),
                              ),
                              if (_points.length > 1)
                                Marker(
                                  point: _points.last,
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.topCenter,
                                  child: RunWaypointMarker(
                                    kind: RunWaypointKind.finish,
                                    label: l10n.running_pinEnd,
                                  ),
                                ),
                            ],
                          ),
                          const RunMapAttribution(),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: AppColors.surfaceDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _DetailStat(
                            label: l10n.running_distance,
                            value: '${distanceKm.toStringAsFixed(2)} km',
                          ),
                          _DetailStat(
                            label: l10n.running_elevation,
                            value: '+$ascent m',
                          ),
                          _DetailStat(
                            label: l10n.running_elevation,
                            value: '-$descent m',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: RunMapStyle.accent(context),
                          foregroundColor: RunMapStyle.foreground(context),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RunTrackingScreen(route: current),
                          ),
                        ),
                        icon: const Icon(Icons.directions_run, size: 20),
                        label: Text(
                          l10n.run_start,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});
  final String label;
  final String value;

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
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
