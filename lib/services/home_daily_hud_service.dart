import '../l10n/app_localizations.dart';
import 'progress_store.dart';

class HomeDailyHudLine {
  const HomeDailyHudLine(this.text, {this.indent = 0});

  final String text;
  final double indent;
}

class HomeDailyHudService {
  HomeDailyHudService._();

  static List<HomeDailyHudLine> dailyLines(AppLocalizations l10n, {DateTime? day}) {
    final target = day ?? DateTime.now();
    final steps = ProgressStore.stepsForDay(target);
    final totalBurn = ProgressStore.totalBurnKcalForDay(target);
    final runMeters = ProgressStore.runMetersForDay(target);
    final food = ProgressStore.foodTotalsForDay(target);
    final sleepMinutes = _sleepMinutesForHud(target);

    const macroIndent = 12.0;
    final lines = <HomeDailyHudLine>[
      HomeDailyHudLine(l10n.home_hudSteps(steps ?? 0)),
      HomeDailyHudLine(l10n.home_hudBurned(totalBurn)),
    ];

    if (runMeters > 0) {
      lines.add(HomeDailyHudLine(l10n.home_hudDistanceRan(_formatKm(runMeters))));
    }

    lines.add(HomeDailyHudLine(l10n.home_hudCaloriesIn(food.kcal)));
    lines.add(
      HomeDailyHudLine(
        l10n.home_hudProtein(food.p.round()),
        indent: macroIndent,
      ),
    );
    lines.add(
      HomeDailyHudLine(
        l10n.home_hudCarbs(food.c.round()),
        indent: macroIndent,
      ),
    );
    lines.add(
      HomeDailyHudLine(
        l10n.home_hudFats(food.f.round()),
        indent: macroIndent,
      ),
    );
    lines.add(HomeDailyHudLine(_recoveryLine(l10n, sleepMinutes)));
    return lines;
  }

  static int? _sleepMinutesForHud(DateTime day) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    if (isToday) return ProgressStore.lastNightSleepMinutes;
    return ProgressStore.sleepForWakeDay(day);
  }

  static String _recoveryLine(AppLocalizations l10n, int? minutes) {
    if (minutes == null || minutes <= 0) {
      return l10n.home_hudRecoveryNoData;
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final sleepText = hours > 0 && mins > 0
        ? l10n.home_hudSleepDuration(hours, mins)
        : hours > 0
            ? l10n.home_hudSleepDurationHours(hours)
            : l10n.home_hudSleepDurationMinutes(mins);
    final quality = _sleepQuality(l10n, minutes);
    return l10n.home_hudRecovery(sleepText, quality);
  }

  static String _sleepQuality(AppLocalizations l10n, int minutes) {
    if (minutes < 360) return l10n.home_hudSleepQualityBad;
    if (minutes < 480) return l10n.home_hudSleepQualityGood;
    return l10n.home_hudSleepQualityPerfect;
  }

  static String _formatKm(double meters) {
    final km = meters / 1000.0;
    final formatted =
        km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
    final localized = ProgressStore.useGerman
        ? formatted.replaceAll('.', ',')
        : formatted;
    return '$localized km';
  }
}
