import 'package:goon_tracker/domain/entities/user_session.dart';

class StatsService {
  int calculateTotalMinutes(List<UserSessionEntity> sessions) {
    return sessions.fold(0, (sum, session) => sum + session.totalMinutes);
  }

  int calculateTodayMinutes(List<UserSessionEntity> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return sessions
        .where((s) => s.startTime.isAfter(today))
        .fold(0, (sum, session) => sum + session.totalMinutes);
  }

  Map<DateTime, int> calculateWeeklySummary(List<UserSessionEntity> sessions) {
    final summary = <DateTime, int>{};
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      summary[date] = 0;
    }

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      if (summary.containsKey(sessionDate)) {
        summary[sessionDate] = summary[sessionDate]! + session.totalMinutes;
      }
    }
    return summary;
  }

  Map<DateTime, int> calculateMonthlySummary(List<UserSessionEntity> sessions) {
    final summary = <DateTime, int>{};
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      summary[date] = 0;
    }

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      if (summary.containsKey(sessionDate)) {
        summary[sessionDate] = summary[sessionDate]! + session.totalMinutes;
      }
    }
    return summary;
  }

  int calculateStreak(List<UserSessionEntity> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates.first != today && dates.first != yesterday) {
      return 0;
    }

    int streak = 0;
    DateTime currentDay = dates.first;

    for (final date in dates) {
      if (date == currentDay) {
        streak++;
        currentDay = currentDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
