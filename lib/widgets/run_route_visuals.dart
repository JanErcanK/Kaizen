import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/routing_service.dart';
import '../theme/app_colors.dart';
import '../theme/green_screen_style.dart';

class RunMapStyle {
  static const route = GreenScreenStyle.accent;
  static const ink = Color(0xFF30471E);
  static const finish = Color(0xFF527E20);
  static Color foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? ink : Colors.white;
  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFC6E89A)
      : GreenScreenStyle.ink;
}

enum RunWaypointKind { start, via, finish }

class RunMapAttribution extends StatelessWidget {
  const RunMapAttribution({
    super.key,
    this.source = '© OpenStreetMap contributors',
  });
  final String source;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            'flutter_map · $source',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ),
      ),
    ),
  );
}

/// A restrained map badge with an anchored point and a single entrance motion.
class RunWaypointMarker extends StatelessWidget {
  const RunWaypointMarker({super.key, required this.kind, required this.label});
  final RunWaypointKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final via = kind == RunWaypointKind.via;
    final color = kind == RunWaypointKind.finish
        ? RunMapStyle.finish
        : RunMapStyle.ink;
    return Semantics(
      label: label,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - value)),
            child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: via ? Colors.white : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: RunMapStyle.ink.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: via
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: RunMapStyle.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      kind == RunWaypointKind.start
                          ? Icons.play_arrow_rounded
                          : Icons.flag_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RunRouteSummary extends StatelessWidget {
  const RunRouteSummary({super.key, required this.route});
  final RouteResult route;

  @override
  Widget build(BuildContext context) {
    final de = Localizations.localeOf(context).languageCode == 'de';
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Container(
      key: const Key('run-route-summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RunMapStyle.accent(context).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RunMapStyle.accent(context).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _RouteMetric(
                  label: de ? 'Distanz' : 'Distance',
                  value: NumberFormat(
                    '0.00',
                    de ? 'de' : 'en',
                  ).format(route.distanceKm),
                  unit: 'km',
                  icon: Icons.route_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RouteMetric(
                  label: de ? 'Aufstieg' : 'Ascent',
                  value: number.format(route.ascentMeters.round()),
                  unit: de ? 'hm' : 'm',
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${de ? 'Abstieg' : 'Descent'}  ${number.format(route.descentMeters.round())} m',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
  final String label, value, unit;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: RunMapStyle.accent(context)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
