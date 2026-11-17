import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/health_dashboard.dart';
import '../models/profile_health_metric.dart';
import '../navigation/app_tab_navigation.dart';
import '../services/health_dashboard_service.dart';
import '../services/progress_store.dart';
import '../services/profile_health_data.dart';
import '../theme/app_colors.dart';

class ProfileHealthCard extends StatefulWidget {
  const ProfileHealthCard({super.key, this.service});
  final HealthDashboardService? service;

  @override
  State<ProfileHealthCard> createState() => _ProfileHealthCardState();
}

class _ProfileHealthCardState extends State<ProfileHealthCard>
    with WidgetsBindingObserver {
  HealthDashboardService get service =>
      widget.service ?? HealthDashboardService.instance;
  ProfileHealthMetric _metric = ProfileHealthMetric.steps;
  int _days = 7;
  DateTime? _selectedDay;
  final _sources = <ProfileHealthMetric, String>{};
  bool _busy = false;
  HealthConnectionStatus? _status;
  bool get de => Localizations.localeOf(context).languageCode == 'de';
  String t(String german, String english) => de ? german : english;

  @override
  void initState() {
    super.initState();
    _metric =
        ProfileHealthMetric.values
            .where((m) => profileHealthData(m).series.isNotEmpty)
            .firstOrNull ??
        ProfileHealthMetric.steps;
    WidgetsBinding.instance.addObserver(this);
    AppTabNavigation.selectedTab.addListener(_refreshIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppTabNavigation.selectedTab.removeListener(_refreshIfNeeded);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshIfNeeded();
  }

  void _refreshIfNeeded() {
    if (!mounted ||
        _busy ||
        AppTabNavigation.selectedTab.value != AppTabNavigation.profile ||
        !ProgressStore.healthDashboardConnected) {
      return;
    }
    final last = ProgressStore.healthDashboard.syncedAt;
    if (last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 15)) {
      unawaited(_sync());
    }
  }

  Future<void> _sync({bool connect = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final status = await service.sync(requestPermission: connect);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = status;
      if (connect && profileHealthData(_metric).series.isEmpty) {
        _metric =
            ProfileHealthMetric.values
                .where((m) => profileHealthData(m).series.isNotEmpty)
                .firstOrNull ??
            _metric;
      }
    });
  }

  String label(ProfileHealthMetric metric) => switch (metric) {
    ProfileHealthMetric.sleep => t('Schlaf', 'Sleep'),
    ProfileHealthMetric.steps => t('Schritte', 'Steps'),
    ProfileHealthMetric.activeEnergy => t('Aktivität', 'Activity'),
    ProfileHealthMetric.workouts => t('Trainings', 'Workouts'),
    ProfileHealthMetric.restingHeartRate => t('Ruhepuls', 'Resting heart rate'),
    ProfileHealthMetric.hrv => 'HRV',
    ProfileHealthMetric.weight => t('Gewicht', 'Weight'),
    ProfileHealthMetric.calorieBurn => t('Verbrauch', 'Burned'),
    ProfileHealthMetric.water => t('Wasser', 'Water'),
    ProfileHealthMetric.afterburn => t('Nachbrennen', 'Afterburn'),
    ProfileHealthMetric.calorieIntake => t('Aufnahme', 'Intake'),
    ProfileHealthMetric.protein => t('Eiweiß', 'Protein'),
    ProfileHealthMetric.fat => t('Fett', 'Fat'),
    ProfileHealthMetric.carbs => t('Kohlenhydrate', 'Carbs'),
  };
  IconData icon(ProfileHealthMetric metric) => switch (metric) {
    ProfileHealthMetric.sleep => Icons.bedtime_outlined,
    ProfileHealthMetric.steps => Icons.directions_walk_rounded,
    ProfileHealthMetric.activeEnergy => Icons.local_fire_department_outlined,
    ProfileHealthMetric.workouts => Icons.fitness_center_rounded,
    ProfileHealthMetric.restingHeartRate => Icons.favorite_border_rounded,
    ProfileHealthMetric.hrv => Icons.monitor_heart_outlined,
    ProfileHealthMetric.weight => Icons.monitor_weight_outlined,
    ProfileHealthMetric.calorieBurn => Icons.whatshot_outlined,
    ProfileHealthMetric.water => Icons.water_drop_outlined,
    ProfileHealthMetric.afterburn => Icons.bolt_rounded,
    ProfileHealthMetric.calorieIntake => Icons.restaurant_outlined,
    ProfileHealthMetric.protein => Icons.egg_outlined,
    ProfileHealthMetric.fat => Icons.opacity_outlined,
    ProfileHealthMetric.carbs => Icons.grass_rounded,
  };
  String value(double number, {bool workoutCount = false}) {
    if (workoutCount) {
      final count = number == number.roundToDouble()
          ? number.round().toString()
          : number.toStringAsFixed(1);
      return '${de ? count.replaceAll('.', ',') : count} ${t('Trainings', 'workouts')}';
    }
    if (_metric == ProfileHealthMetric.sleep) {
      final minutes = number.round();
      return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
    }
    final text = number.toStringAsFixed(
      _metric == ProfileHealthMetric.weight ? 1 : 0,
    );
    final formatted = de ? text.replaceAll('.', ',') : text;
    return '$formatted${switch (_metric) {
      ProfileHealthMetric.activeEnergy || ProfileHealthMetric.calorieBurn || ProfileHealthMetric.afterburn || ProfileHealthMetric.calorieIntake => ' kcal',
      ProfileHealthMetric.water => ' ml',
      ProfileHealthMetric.protein || ProfileHealthMetric.fat || ProfileHealthMetric.carbs => ' g',
      ProfileHealthMetric.workouts => ' min',
      ProfileHealthMetric.restingHeartRate => ' bpm',
      ProfileHealthMetric.hrv => ' ms',
      ProfileHealthMetric.weight => ' kg',
      _ => '',
    }}';
  }

  String date(DateTime d) => '${d.day}.${d.month}.';

  Future<void> _connectionDetails() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('Deine Gesundheitsverbindung', 'Your health connection'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Kaizen liest Schlaf, Schritte, Aktivitätskalorien, Trainings, Ruhepuls, HRV und Gewicht. Du wählst im System, welche Bereiche du freigibst.',
                'Kaizen reads sleep, steps, active calories, workouts, resting heart rate, HRV and weight. You choose which categories to share in system settings.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Auch ohne Smartwatch: Dein iPhone kann Schritte in Apple Health erfassen. Auf unterstützten Android-Handys zählt Health Connect selbst Schritte; andernfalls verbindest du eine kompatible Schrittzähler-App mit Health Connect. Trage dein Handy beim Gehen bei dir.',
                'No smartwatch needed: your iPhone can record steps in Apple Health. On supported Android phones, Health Connect counts steps itself; otherwise, connect a compatible step-counting app to Health Connect. Carry your phone while walking.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Mit Smartwatch: Verbinde die Uhr mit ihrer Hersteller-App und aktiviere deren Weitergabe an Apple Health oder Health Connect. Nur dort verfügbare und freigegebene Werte werden importiert. Ruhepuls und HRV brauchen eine geeignete Messquelle; Schlaf und Gewicht können auch aus kompatiblen Apps oder Einträgen stammen.',
                'With a smartwatch: connect it to its companion app and enable sharing with Apple Health or Health Connect. Only available, shared values are imported. Resting heart rate and HRV need a suitable measurement source; sleep and weight can also come from compatible apps or entries.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Die letzten 28 Tage werden beim Öffnen des Profils aktualisiert. Die importierten Verläufe bleiben lokal und werden nicht automatisch an KI oder Freunde gesendet. Sie verändern keine Kaizen-Trainings, XP oder Kalorienziele.',
                'The last 28 days refresh when you open your profile. Imported trends stay on this device and are not automatically sent to AI or friends. They do not change Kaizen workouts, XP or calorie targets.',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t(
                'Freigaben ändern: iPhone → Health → Profil → Apps → Kaizen. Android → Einstellungen → Health Connect → App-Berechtigungen → Kaizen.',
                'Change access: iPhone → Health → Profile → Apps → Kaizen. Android → Settings → Health Connect → App permissions → Kaizen.',
              ),
            ),
            if (ProgressStore.healthDashboardConnected) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        await service.disconnect();
                        if (mounted) {
                          setState(() {
                            _status = null;
                            _selectedDay = null;
                          });
                        }
                      },
                icon: const Icon(Icons.link_off),
                label: Text(
                  t(
                    'Import stoppen & lokale Verläufe löschen',
                    'Stop import & clear local trends',
                  ),
                ),
              ),
              Text(
                t(
                  'Die Originaldaten und Systemfreigaben bleiben bestehen. Freigaben kannst du zusätzlich im System widerrufen.',
                  'Original data and system permissions remain. You can revoke access separately in system settings.',
                ),
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: ProgressStore.listenable(),
    builder: (context, _, child) {
      final connected = ProgressStore.healthDashboardConnected;
      final supported = service.gateway.supported;
      final data = profileHealthData(_metric);
      final series =
          data.series
              .where((s) => s.sourceId == _sources[_metric])
              .firstOrNull ??
          data.series.firstOrNull;
      final localSource = series?.sourceId == kaizenHealthSourceId;
      String format(double n) =>
          value(n, workoutCount: series?.method == 'workoutCount');
      final now = DateTime.now();
      final today = healthDay(now);
      final first = DateTime(today.year, today.month, today.day - _days + 1);
      final recent =
          series?.days
              .where((d) => !d.day.isBefore(first) && !d.day.isAfter(today))
              .toList() ??
          <HealthDayValue>[];
      final chartSeries = data.state == HealthReadState.denied || recent.isEmpty
          ? null
          : series;
      final selected = _selectedDay == null
          ? recent.lastOrNull
          : series?.on(_selectedDay!);
      final selectedDate = _selectedDay ?? selected?.day ?? today;
      return Container(
        key: const ValueKey('profile-health'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppColors.surfaceDecoration(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    t('Deine Gesundheit', 'Your health'),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _connectionDetails,
                  tooltip: t(
                    'Verbindung & Datenschutz',
                    'Connection & privacy',
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                ),
              ],
            ),
            Text(
              t(
                'Verstehe deinen Verlauf – Tag für Tag.',
                'Understand your trends, day by day.',
              ),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (data.state == HealthReadState.denied)
              _notice(
                t('Freigabe fehlt', 'Permission needed'),
                t(
                  'Du kannst diesen Bereich über „Freigaben prüfen“ erlauben. Die anderen Bereiche bleiben nutzbar.',
                  'Allow this category using “Review permissions”. Other categories remain available.',
                ),
              )
            else if (chartSeries == null)
              _notice(
                t(
                  'Noch keine Daten für diesen Zeitraum',
                  'No data for this period yet',
                ),
                _missingDataHint(),
              )
            else ...[
              if (data.state == HealthReadState.failed ||
                  (!localSource &&
                      (_status == HealthConnectionStatus.failed ||
                          _status == HealthConnectionStatus.unavailable ||
                          _status == HealthConnectionStatus.updateRequired)))
                _notice(
                  t('Älterer Datenstand', 'Older data'),
                  t(
                    'Dieser Verlauf konnte gerade nicht aktualisiert werden.',
                    'This trend could not be refreshed.',
                  ),
                ),
              Text(
                '${label(_metric)} · ${date(selectedDate)}${selectedDate == today ? t(' · heute', ' · today') : ''}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                selected == null ? '—' : format(selected.value),
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (selected == null)
                Text(
                  t(
                    'Für diesen Tag liegt keine Messung vor.',
                    'No measurement for this day.',
                  ),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              if (selected?.estimated == true)
                Text(
                  t(
                    'Schlafzeitfenster · keine vollständigen Schlafphasen',
                    'Sleep window · complete sleep stages unavailable',
                  ),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              if (selectedDate == today &&
                  {_metric}.intersection({
                    ProfileHealthMetric.steps,
                    ProfileHealthMetric.activeEnergy,
                    ProfileHealthMetric.workouts,
                  }).isNotEmpty)
                Text(
                  t(
                    'Heute läuft noch – der Wert kann steigen.',
                    'Today is still in progress; this value may increase.',
                  ),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              const SizedBox(height: 16),
              _HealthChart(
                key: const ValueKey('health-trend-chart'),
                metric: _metric,
                first: first,
                days: _days,
                series: chartSeries,
                selectedDay: selectedDate,
                format: format,
                onSelect: (day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: 6),
              Text(
                t(
                  localSource
                      ? 'Tag antippen · Lücke = kein Eintrag'
                      : 'Tag antippen · Lücke = keine Messung',
                  localSource
                      ? 'Tap a day · gap = no entry'
                      : 'Tap a day · gap = no measurement',
                ),
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 16),
            ],
            if (!supported && !localSource)
              _notice(
                t('Auf deinem Smartphone verbinden', 'Connect on your phone'),
                t(
                  'Öffne Kaizen auf deinem iPhone oder Android-Smartphone und verbinde Apple Health oder Health Connect. Daten von deinem Handy, kompatiblen Apps und einer optionalen Smartwatch erscheinen dort gemeinsam.',
                  'Open Kaizen on your iPhone or Android phone and connect Apple Health or Health Connect. Data from your phone, compatible apps and an optional smartwatch appears together there.',
                ),
              ),
            if (supported && !connected && !localSource)
              _notice(
                t(
                  'Mit Handy und optionaler Uhr',
                  'Phone first, watch optional',
                ),
                t(
                  'Eine Smartwatch ist nicht erforderlich. Verbinde deine Gesundheits-App für verfügbare Schritte, Schlaf, Trainings und weitere Werte. Du entscheidest, was Kaizen lesen darf.',
                  'A smartwatch is not required. Connect your health app for available steps, sleep, workouts and more. You choose what Kaizen may read.',
                ),
              ),
            if (_status == HealthConnectionStatus.unavailable ||
                _status == HealthConnectionStatus.updateRequired) ...[
              _notice(
                t('Health Connect einrichten', 'Set up Health Connect'),
                t(
                  'Health Connect fehlt, benötigt ein Update oder ist auf diesem Gerät nicht verfügbar.',
                  'Health Connect is missing, needs an update or is unavailable on this device.',
                ),
              ),
              if (_status == HealthConnectionStatus.updateRequired)
                TextButton(
                  onPressed: () => service.gateway.install(),
                  child: Text(
                    t('Installieren / aktualisieren', 'Install / update'),
                  ),
                ),
            ],
            if (_status == HealthConnectionStatus.failed)
              _notice(
                t('Aktualisierung nicht möglich', 'Unable to refresh'),
                t(
                  'Bitte versuche es erneut. Gespeicherte Werte sind als älterer Stand gekennzeichnet.',
                  'Please try again. Saved values are marked as older data.',
                ),
              ),
            if (supported)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('health-connect'),
                      onPressed: _busy
                          ? null
                          : () => _sync(connect: !connected),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(connected ? Icons.sync : Icons.link, size: 18),
                      label: Text(
                        _busy
                            ? t(
                                'Daten werden geladen …',
                                'Loading health data …',
                              )
                            : connected
                            ? t('Aktualisieren', 'Refresh')
                            : '${service.gateway.platform} ${t('verbinden', 'connect')}',
                      ),
                    ),
                  ),
                  if (connected)
                    IconButton(
                      onPressed: _busy ? null : () => _sync(connect: true),
                      tooltip: t('Freigaben prüfen', 'Review permissions'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final metric in ProfileHealthMetric.values)
                  ChoiceChip(
                    key: ValueKey('health-metric-${metric.name}'),
                    selected: _metric == metric,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontFamily: 'Roboto',
                      color: _metric == metric
                          ? AppColors.onSelected
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    avatar: Icon(
                      icon(metric),
                      size: 16,
                      color: _metric == metric
                          ? AppColors.onSelected
                          : AppColors.textMuted,
                    ),
                    label: Text(label(metric)),
                    onSelected: (_) => setState(() {
                      _metric = metric;
                      _selectedDay = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(t('7 Tage', '7 days'))),
                ButtonSegment(value: 28, label: Text(t('28 Tage', '28 days'))),
              ],
              selected: {_days},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() {
                _days = v.first;
                _selectedDay = null;
              }),
            ),
            if (chartSeries != null) ...[
              const SizedBox(height: 14),
              _notice(
                t('Dein Verlauf', 'Your trend'),
                _trend(chartSeries, today, format),
              ),
              if (data.series.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: chartSeries.sourceId,
                  isExpanded: true,
                  key: ValueKey('${_metric.name}-${chartSeries.sourceId}'),
                  decoration: InputDecoration(
                    labelText: t('Datenquelle', 'Data source'),
                  ),
                  items: [
                    for (final source in data.series)
                      DropdownMenuItem(
                        value: source.sourceId,
                        child: Text(
                          source.source,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _sources[_metric] = id!;
                    _selectedDay = null;
                  }),
                )
              else
                Text(
                  '${t('Quelle', 'Source')}: ${chartSeries.source}${chartSeries.method == 'SDNN' || chartSeries.method == 'RMSSD' ? ' · ${chartSeries.method}' : ''}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              const SizedBox(height: 8),
              Text(
                _explanation(chartSeries),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            if (!localSource && data.checkedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                '${t('Stand', 'Updated')}: ${date(data.checkedAt!)} ${data.checkedAt!.hour.toString().padLeft(2, '0')}:${data.checkedAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _notice(String title, String body) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.softSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );

  String _trend(
    HealthSeries series,
    DateTime today,
    String Function(double) format,
  ) {
    final start = DateTime(today.year, today.month, today.day - 7);
    final previous = DateTime(today.year, today.month, today.day - 14);
    final current = series.days
        .where(
          (d) =>
              !d.day.isBefore(start) && d.day.isBefore(today) && !d.estimated,
        )
        .toList();
    final before = series.days
        .where(
          (d) =>
              !d.day.isBefore(previous) &&
              d.day.isBefore(start) &&
              !d.estimated,
        )
        .toList();
    if (current.length < 3) {
      return t(
        'Für einen aussagekräftigen Vergleich fehlen noch Messungen an mindestens drei abgeschlossenen Tagen innerhalb einer Woche. Fehlende Tage zählen nicht als null.',
        'A useful comparison needs measurements on at least three completed days within a week. Missing days are not counted as zero.',
      );
    }
    final average =
        current.fold(0.0, (sum, d) => sum + d.value) / current.length;
    final intro = t(
      'Ø ${format(average)} an ${current.length} erfassten Tagen der letzten abgeschlossenen Woche.',
      'Average ${format(average)} across ${current.length} recorded days in the last completed week.',
    );
    if (before.length < 3) {
      return '$intro ${t('Für den Vergleich zur Vorwoche fehlen noch Daten.', 'More data is needed to compare with the preceding week.')}';
    }
    final previousAverage =
        before.fold(0.0, (sum, d) => sum + d.value) / before.length;
    final diff = average - previousAverage;
    return '$intro ${t('Vorwoche', 'Previous week')}: ${format(previousAverage)} (${before.length} ${t('Tage', 'days')}). ${t('Veränderung', 'Change')}: ${diff < 0 ? '−' : '+'}${format(diff.abs())}.';
  }

  String _explanation(HealthSeries? series) => switch (_metric) {
    ProfileHealthMetric.sleep => t(
      'Schlafphasen werden ohne Doppelzählung zusammengefasst; Wachphasen zählen nicht als Schlaf. Die Nacht gehört zum Aufwachdatum, Nickerchen zählen dazu.',
      'Sleep stages are combined without double counting; awake periods are excluded. Nights belong to their wake-up date, including naps.',
    ),
    ProfileHealthMetric.steps =>
      series?.sourceId == kaizenHealthSourceId
          ? t(
              'In Kaizen gespeicherte Tageswerte. Über die Datenquelle kannst du auch deinen importierten Verlauf ansehen; beide werden einzeln angezeigt.',
              'Daily step totals saved in Kaizen. Use Data source to view your imported trend as well; each source is shown separately.',
            )
          : t(
              'Schritte können vom Handy, einer Uhr oder kompatiblen Apps stammen. Die Summe kommt aus deiner Gesundheits-App, die überlappende Quellen priorisiert. Unbestätigte Nullwerte bleiben als Lücke sichtbar; Kaizen-Schritte werden nicht zusätzlich addiert.',
              'Steps can come from your phone, a watch or compatible apps. Your health app prioritizes overlapping sources for the total. Unconfirmed zero values remain gaps; Kaizen steps are not added again.',
            ),
    ProfileHealthMetric.activeEnergy => t(
      'Geschätzte Aktivitätskalorien der ausgewählten Quelle, ohne Ruheenergie. Sie werden nicht zu Kaizens berechnetem Verbrauch addiert.',
      'Estimated active calories from the selected source, excluding resting energy. They are not added to Kaizen’s calculated burn.',
    ),
    ProfileHealthMetric.workouts =>
      series?.method == 'workoutCount'
          ? t(
              'Anzahl deiner in Kaizen abgeschlossenen Trainings pro erfasstem Tag. Importierte Trainingsminuten findest du über die Datenquelle.',
              'Number of workouts completed in Kaizen per recorded day. Imported workout minutes are available through Data source.',
            )
          : t(
              'Aufgezeichnete Trainingsminuten der ausgewählten Quelle. Überlappende Aufzeichnungen zählen einmal. Sie erzeugen keine zusätzlichen XP oder Kaizen-Einträge.',
              'Recorded workout minutes from the selected source. Overlapping recordings count once. They do not generate extra XP or Kaizen entries.',
            ),
    ProfileHealthMetric.restingHeartRate => t(
      'Der Tageswert ist der Median der Ruhepulsmessungen. Vergleiche deinen eigenen Verlauf; einzelne Veränderungen sind keine Diagnose.',
      'The daily value is the median of resting heart rate measurements. Compare your own trend; individual changes are not a diagnosis.',
    ),
    ProfileHealthMetric.hrv => t(
      'Tagesmedian · ${series?.method ?? ''}. HRV beschreibt Unterschiede zwischen Herzschlagabständen. SDNN und RMSSD sind verschiedene Verfahren und werden nicht vermischt. Ein Einzelwert bewertet nicht deine Erholung.',
      'Daily median · ${series?.method ?? ''}. HRV describes variation between heartbeats. SDNN and RMSSD are different methods and are not combined. One reading does not rate your recovery.',
    ),
    ProfileHealthMetric.weight =>
      series?.sourceId == kaizenHealthSourceId
          ? t(
              'Deine Gewichtseinträge in Kaizen, jeweils der letzte Wert pro Tag. Einen neuen Wert kannst du direkt unter dieser Karte hinzufügen.',
              'Your weight entries in Kaizen, using the last value each day. Add a new entry directly below this card.',
            )
          : t(
              'Die letzte Messung pro Tag. Lücken bleiben sichtbar; dein manuell eingetragenes Profilgewicht wird nicht überschrieben. Für Veränderungen zählt der Verlauf über mehrere Tage.',
              'The last measurement each day. Gaps remain visible; your manually entered profile weight is not overwritten. Look at several days to understand changes.',
            ),
    ProfileHealthMetric.calorieBurn => t(
      'Geschätzter Verbrauch aus deinen in Kaizen erfassten Schritten und Trainings. Ruheenergie und Nachbrennen sind hier nicht enthalten.',
      'Estimated burn from steps and workouts recorded in Kaizen. Resting energy and afterburn are not included here.',
    ),
    ProfileHealthMetric.water => t(
      'Deine in Kaizen eingetragenen Trinkmengen pro Tag. Die Summe bildet nur ab, was du erfasst hast.',
      'Water logged in Kaizen each day. Totals reflect only the drinks you recorded.',
    ),
    ProfileHealthMetric.afterburn => t(
      'Geschätzter zusätzlicher Verbrauch nach deinen Kaizen-Trainings. Das ist ein Rechenmodell und keine gemessene Kalorienmenge.',
      'Estimated additional energy use after Kaizen workouts. This is a calculation, not a measured calorie value.',
    ),
    ProfileHealthMetric.calorieIntake => t(
      'Kalorien aus deinen erfassten Mahlzeiten. Unvollständige Einträge ergeben unvollständige Tagessummen.',
      'Calories from logged meals. Incomplete entries produce incomplete daily totals.',
    ),
    ProfileHealthMetric.protein ||
    ProfileHealthMetric.fat ||
    ProfileHealthMetric.carbs => t(
      'Tagessumme aus deinen erfassten Lebensmitteln. Für einen hilfreichen Vergleich erfasse deine Mahlzeiten möglichst vollständig.',
      'Daily totals from logged foods. Log meals consistently for a useful comparison.',
    ),
  };

  String _missingDataHint() {
    if (_metric.importedMetric == null) {
      return switch (_metric) {
        ProfileHealthMetric.water => t(
          'Trage deine Getränke im Wassertracking ein. Deine Mengen erscheinen dann hier.',
          'Log drinks in water tracking to see your daily amounts here.',
        ),
        ProfileHealthMetric.calorieBurn || ProfileHealthMetric.afterburn => t(
          'Erfasse ein Training in Kaizen. Hier siehst du anschließend den geschätzten Verlauf.',
          'Complete a workout in Kaizen to see the estimated trend here.',
        ),
        _ => t(
          'Füge Lebensmittel zu „Heute essen“ hinzu. Kalorien und Makros erscheinen anschließend hier.',
          'Add foods to today’s intake to see calories and macros here.',
        ),
      };
    }
    final hint = switch (_metric) {
      ProfileHealthMetric.steps =>
        service.gateway.platform == 'Apple Health'
            ? t(
                'Dein iPhone kann Schritte auch ohne Uhr zählen. Trage es beim Gehen bei dir und prüfe, ob in Apple Health Schritte ankommen.',
                'Your iPhone can count steps without a watch. Carry it while walking and check that steps appear in Apple Health.',
              )
            : t(
                'Eine Uhr ist nicht nötig. Prüfe, ob Health Connect Schritte von deinem Handy erhält. Falls nicht, aktiviere die Weitergabe in einer kompatiblen Schrittzähler-App. Neue Schritte können verzögert erscheinen.',
                'A watch is not needed. Check whether Health Connect receives steps from your phone. If not, enable sharing in a compatible step-counting app. New steps may take time to appear.',
              ),
      ProfileHealthMetric.sleep => t(
        'Schlaf kann aus einer kompatiblen App, einem Eintrag oder einer Uhr kommen. Das Handy allein liefert keine automatisch gemessenen Schlafphasen. Prüfe die Schlafdaten in deiner Gesundheits-App.',
        'Sleep can come from a compatible app, an entry or a watch. A phone alone does not provide automatically measured sleep stages. Check the sleep data in your health app.',
      ),
      ProfileHealthMetric.activeEnergy => t(
        'Aktivitätskalorien erscheinen, wenn dein Handy, eine Fitness-App oder eine Uhr sie an deine Gesundheits-App übermittelt. Nicht jede Quelle teilt diese Schätzung.',
        'Active calories appear when your phone, a fitness app or a watch shares them with your health app. Not every source shares this estimate.',
      ),
      ProfileHealthMetric.workouts => t(
        'Schließe ein Training in Kaizen ab oder importiere aufgezeichnete Trainings aus Apple Health oder Health Connect. Beides findest du hier über die Datenquelle.',
        'Complete a workout in Kaizen or import recorded workouts from Apple Health or Health Connect. Both appear here through Data source.',
      ),
      ProfileHealthMetric.restingHeartRate || ProfileHealthMetric.hrv => t(
        'Dieser Wert braucht eine passende Messquelle, etwa eine kompatible Uhr oder einen Sensor mit zugehöriger App. Das Handy allein misst ihn hier nicht. Prüfe, ob die Quelle genau diesen Wert teilt.',
        'This value needs a suitable measurement source, such as a compatible watch or sensor with its app. The phone alone does not measure it here. Check that the source shares this specific value.',
      ),
      ProfileHealthMetric.weight => t(
        'Eine Uhr ist nicht nötig. Gewicht kann aus Einträgen oder einer Waagen-App in Apple Health oder Health Connect stammen. Dein manuell in Kaizen eingetragenes Gewicht bleibt separat erhalten.',
        'A watch is not needed. Weight can come from entries or a scale app in Apple Health or Health Connect. Weight entered manually in Kaizen stays separate.',
      ),
      _ => '',
    };
    return '$hint ${t('Prüfe auch die Lesefreigabe für Kaizen.', 'Also check Kaizen’s read permission.')}';
  }
}

class _HealthChart extends StatelessWidget {
  const _HealthChart({
    super.key,
    required this.metric,
    required this.first,
    required this.days,
    required this.series,
    required this.selectedDay,
    required this.format,
    required this.onSelect,
  });
  final ProfileHealthMetric metric;
  final DateTime first, selectedDay;
  final int days;
  final HealthSeries series;
  final String Function(double) format;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      days,
      (i) => DateTime(first.year, first.month, first.day + i),
    );
    final values = dates.map(series.on).toList();
    final numbers = values
        .whereType<HealthDayValue>()
        .map((v) => v.value)
        .toList();
    final max = numbers.isEmpty
        ? 1.0
        : math.max(1.0, numbers.reduce(math.max) * 1.12);
    final isLine =
        metric == ProfileHealthMetric.weight ||
        metric == ProfileHealthMetric.hrv ||
        metric == ProfileHealthMetric.restingHeartRate;
    final min = !isLine || numbers.isEmpty
        ? 0.0
        : math.max(
            0.0,
            numbers.reduce(math.min) -
                math.max(2, (max - numbers.reduce(math.min)) * .3),
          );
    final de = Localizations.localeOf(context).languageCode == 'de';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                format(max),
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                isLine
                    ? (de ? 'Tageswerte' : 'Daily values')
                    : (de ? 'Tagessummen' : 'Daily totals'),
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 135,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HealthChartPainter(
                      values: values,
                      selected: dates.indexOf(healthDay(selectedDay)),
                      min: min,
                      max: max,
                      line: isLine,
                      color: AppColors.primary,
                      stroke: AppColors.stroke,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < dates.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: dates[i] == healthDay(selectedDay),
                            label:
                                '${dates[i].day}.${dates[i].month}. ${values[i] == null ? (de ? 'Keine Messung' : 'No measurement') : format(values[i]!.value)}',
                            child: Tooltip(
                              message:
                                  '${dates[i].day}.${dates[i].month}. · ${values[i] == null ? '—' : format(values[i]!.value)}',
                              child: GestureDetector(
                                key: ValueKey(
                                  'health-day-${healthDayKey(dates[i])}',
                                ),
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onSelect(dates[i]),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${format(min)} · ${dates.first.day}.${dates.first.month}.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                '${dates.last.day}.${dates.last.month}.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthChartPainter extends CustomPainter {
  const _HealthChartPainter({
    required this.values,
    required this.selected,
    required this.min,
    required this.max,
    required this.line,
    required this.color,
    required this.stroke,
  });
  final List<HealthDayValue?> values;
  final int selected;
  final double min, max;
  final bool line;
  final Color color, stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width / values.length;
    final baseline = size.height - 4;
    final grid = Paint()
      ..color = stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = baseline * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    Offset? last;
    for (var i = 0; i < values.length; i++) {
      final x = width * (i + .5);
      if (i == selected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(width * i + 1, 0, width - 2, size.height),
            const Radius.circular(6),
          ),
          Paint()..color = color.withValues(alpha: .09),
        );
      }
      final value = values[i];
      if (value == null) {
        last = null;
        continue;
      }
      final y =
          baseline -
          ((value.value - min) / (max - min)).clamp(0.0, 1.0) * (baseline - 5);
      final point = Offset(x, y);
      final paint = Paint()
        ..color = color.withValues(
          alpha: value.estimated ? .45 : (i == selected ? 1 : .75),
        )
        ..strokeWidth = 2.5;
      if (line) {
        if (last != null) canvas.drawLine(last, point, paint);
        canvas.drawCircle(point, i == selected ? 4 : 3, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              x - width * .28,
              math.min(y, baseline - 2),
              x + width * .28,
              baseline,
            ),
            const Radius.circular(4),
          ),
          paint,
        );
      }
      last = point;
    }
  }

  @override
  bool shouldRepaint(covariant _HealthChartPainter oldDelegate) => true;
}
