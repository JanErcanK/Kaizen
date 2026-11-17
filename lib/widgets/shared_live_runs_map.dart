import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n_extension.dart';
import '../models/social_models.dart';
import '../screens/social/friend_live_run_detail_screen.dart';
import '../theme/app_colors.dart';

Color friendAvatarColor(String uid) {
  var hash = 0;
  for (final unit in uid.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, 0.52).toColor();
}

String formatPaceSecPerKm(double? secPerKm, {String fallback = '—'}) {
  if (secPerKm == null || secPerKm.isNaN || secPerKm <= 0 || secPerKm > 3600) {
    return fallback;
  }
  final m = (secPerKm ~/ 60).toString();
  final s = (secPerKm.round() % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

List<LatLng> pointsToLatLng(List<List<double>> points) {
  return points
      .where((p) => p.length >= 2)
      .map((p) => LatLng(p[0], p[1]))
      .toList();
}

class SharedLiveRunsMap extends StatefulWidget {
  const SharedLiveRunsMap({
    super.key,
    required this.runs,
    this.height = 320,
    this.compact = false,
    this.onRunTap,
  });

  final List<FriendLiveRun> runs;
  final double height;
  final bool compact;
  final ValueChanged<FriendLiveRun>? onRunTap;

  @override
  State<SharedLiveRunsMap> createState() => _SharedLiveRunsMapState();
}

class _SharedLiveRunsMapState extends State<SharedLiveRunsMap> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SharedLiveRunsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runs.isNotEmpty &&
        oldWidget.runs.map((r) => r.uid).join(',') !=
            widget.runs.map((r) => r.uid).join(',')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRuns());
    }
  }

  void _fitToRuns() {
    if (!mounted || !_mapReady || widget.runs.isEmpty) return;
    final points = <LatLng>[];
    for (final run in widget.runs) {
      points.add(LatLng(run.latitude, run.longitude));
      points.addAll(pointsToLatLng(run.recordedPoints));
    }
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.all(widget.compact ? 28 : 48),
        maxZoom: 16,
      ),
    );
  }

  void _openDetail(FriendLiveRun run) {
    if (widget.onRunTap != null) {
      widget.onRunTap!(run);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendLiveRunDetailScreen(run: run),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.runs.isEmpty) {
      return Container(
        height: widget.height,
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(
          l10n.sharedRuns_empty,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              widget.runs.first.latitude,
              widget.runs.first.longitude,
            ),
            initialZoom: 13,
            onMapReady: () {
              _mapReady = true;
              _fitToRuns();
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
            PolylineLayer(
              polylines: [
                for (final run in widget.runs)
                  if (run.plannedPoints.length >= 2)
                    Polyline(
                      points: pointsToLatLng(run.plannedPoints),
                      color: friendAvatarColor(run.uid).withValues(alpha: 0.35),
                      strokeWidth: 3,
                    ),
                for (final run in widget.runs)
                  if (run.recordedPoints.length >= 2)
                    Polyline(
                      points: pointsToLatLng(run.recordedPoints),
                      color: friendAvatarColor(run.uid),
                      strokeWidth: 4,
                    ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final run in widget.runs)
                  Marker(
                    point: LatLng(run.latitude, run.longitude),
                    width: widget.compact ? 44 : 52,
                    height: widget.compact ? 44 : 52,
                    child: GestureDetector(
                      onTap: () => _openDetail(run),
                      child: _FriendRunMarker(
                        run: run,
                        compact: widget.compact,
                      ),
                    ),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRunMarker extends StatelessWidget {
  const _FriendRunMarker({required this.run, required this.compact});

  final FriendLiveRun run;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = friendAvatarColor(run.uid);
    final initial = run.displayName.isNotEmpty
        ? run.displayName.characters.first.toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: compact ? 18 : 22,
        backgroundColor: color,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 14 : 16,
          ),
        ),
      ),
    );
  }
}
