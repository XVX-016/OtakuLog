import 'package:otakulog/data/local/retention_preferences_service.dart';

class WrappedTriggerDecision {
  final bool showWeekly;
  final bool showMonthly;

  const WrappedTriggerDecision({
    required this.showWeekly,
    required this.showMonthly,
  });

  bool get hasAny => showWeekly || showMonthly;
}

class WrappedTriggerService {
  String weeklyPeriodKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    final thursday = date.add(Duration(days: 4 - _isoWeekday(date)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week = 1 + ((thursday.difference(firstThursday).inDays) / 7).floor();
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  String monthlyPeriodKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  WrappedTriggerDecision evaluate({
    required RetentionPreferences preferences,
    required bool hasWeeklyData,
    required bool hasMonthlyData,
    DateTime? now,
  }) {
    final weeklyKey = weeklyPeriodKey(now);
    final monthlyKey = monthlyPeriodKey(now);
    return WrappedTriggerDecision(
      showWeekly:
          hasWeeklyData && preferences.lastWeeklyWrappedPeriodKeyShown != weeklyKey,
      showMonthly:
          hasMonthlyData && preferences.lastMonthlyWrappedPeriodKeyShown != monthlyKey,
    );
  }

  int _isoWeekday(DateTime date) {
    final weekday = date.weekday;
    return weekday == DateTime.sunday ? 7 : weekday;
  }
}
