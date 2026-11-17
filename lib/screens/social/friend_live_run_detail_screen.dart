import '../../widgets/app_back_button.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/l10n_extension.dart';
import '../../models/social_models.dart';
import '../../services/social/social_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/shared_live_runs_map.dart';

class FriendLiveRunDetailScreen extends StatefulWidget {
  const FriendLiveRunDetailScreen({super.key, required this.run});

  final FriendLiveRun run;

  @override
  State<FriendLiveRunDetailScreen> createState() =>
      _FriendLiveRunDetailScreenState();
}

class _FriendLiveRunDetailScreenState extends State<FriendLiveRunDetailScreen> {
  final MapController _mapController = MapController();
  Timer? _freshnessTimer;
  bool _mapReady = false;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    SocialService.instance.setFastLivePolling(true);
    SocialService.instance.refreshLiveRunsNow();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    SocialService.instance.setFastLivePolling(false);
    _freshnessTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _fitMap(FriendLiveRun run) {
    if (!mounted || !_mapReady || !_follow) return;
    final points = <LatLng>[
      LatLng(run.latitude, run.longitude),
      ...pointsToLatLng(run.plannedPoints),
      ...pointsToLatLng(run.recordedPoints),
    ];
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<int>(
      valueListenable: SocialService.instance.listenable,
      builder: (context, _, __) {
        final updated = SocialService.instance.friendsLiveRuns
            .where((r) => r.uid == widget.run.uid)
            .cast<FriendLiveRun?>()
            .firstWhere((r) => r != null, orElse: () => null);
        if (updated == null) {
          _mapReady = false;
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(),
              leadingWidth: 44,
              title: Text(widget.run.displayName),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'de'
                      ? 'Dieser Lauf ist beendet oder es werden keine aktuellen Positionsdaten mehr geteilt.'
                      : 'This run has ended or current location updates are no longer being shared.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final run = updated;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMap(run));

        final distKm = run.distanceMeters / 1000.0;
        final currentPace = formatPaceSecPerKm(run.currentPaceSecPerKm);
        final avgPace = formatPaceSecPerKm(run.avgPaceSecPerKm);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: const AppBackButton(),
            leadingWidth: 44,
            backgroundColor: AppColors.background,
            title: Text(
              run.displayName,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                run.paused
                    ? (Localizations.localeOf(context).languageCode == 'de'
                          ? 'Lauf pausiert'
                          : 'Run paused')
                    : run.positionIsStale
                    ? (Localizations.localeOf(context).languageCode == 'de'
                          ? 'Position veraltet – warte auf GPS'
                          : 'Location is stale — waiting for GPS')
                    : (Localizations.localeOf(context).languageCode == 'de'
                          ? 'Live · Aktualisierung etwa alle 5 Sekunden'
                          : 'Live · refreshes about every 5 seconds'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() => _follow = true);
                    _fitMap(run);
                  },
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'de'
                        ? 'Lauf folgen'
                        : 'Follow run',
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 280,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(run.latitude, run.longitude),
                      initialZoom: 14,
                      onMapReady: () {
                        _mapReady = true;
                        _fitMap(run);
                      },
                      onPositionChanged: (_, hasGesture) {
                        if (hasGesture) _follow = false;
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'de.jankilic.kaizen',
                      ),
                      if (run.plannedPoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: pointsToLatLng(run.plannedPoints),
                              color: friendAvatarColor(
                                run.uid,
                              ).withValues(alpha: 0.35),
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      if (run.recordedPoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: pointsToLatLng(run.recordedPoints),
                              color: friendAvatarColor(run.uid),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(run.latitude, run.longitude),
                            width: 48,
                            height: 48,
                            child: CircleAvatar(
                              backgroundColor: friendAvatarColor(run.uid),
                              child: Text(
                                run.displayName.isNotEmpty
                                    ? run.displayName.characters.first
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
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
              ),
              const SizedBox(height: 16),
              Text(
                run.routeName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: l10n.sharedRuns_distance,
                      value: '${distKm.toStringAsFixed(2)} km',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: l10n.sharedRuns_currentPace,
                      value: currentPace,
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatCard(label: l10n.sharedRuns_avgPace, value: avgPace),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.surfaceDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.accentText : AppColors.textPrimary,
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 22 : 18,
            ),
          ),
        ],
      ),
    );
  }
}
