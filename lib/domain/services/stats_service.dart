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
        .fold(0, (sum, s) => sum + s.totalMinutes);
  }

  int calculateStreak(List<UserSessionEntity> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    for (final date in dates) {
      if (date == current || date == current.subtract(const Duration(days: 1))) {
        streak++;
        current = date;
      } else if (date.isBefore(current.subtract(const Duration(days: 1)))) {
        break;
      }
    }
    return streak;
  }

  Map<DateTime, int> calculateWeeklySummary(List<UserSessionEntity> sessions) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    
    final summary = <DateTime, int>{};
    for (final day in last7Days) {
      summary[day] = sessions
          .where((s) => s.startTime.year == day.year && s.startTime.month == day.month && s.startTime.day == day.day)
          .fold(0, (sum, s) => sum + s.totalMinutes);
    }
    return summary;
  }

  double calculateAverageMinutesPerUnit(List<UserSessionEntity> sessions, SessionContentType type) {
    final filteredSessions = sessions.where((s) => s.contentType == type).toList();
    if (filteredSessions.isEmpty) return 0.0;
    final totalMinutes = filteredSessions.fold(0, (sum, s) => sum + s.totalMinutes);
    final totalUnits = filteredSessions.fold(0, (sum, s) => sum + s.unitsConsumed);
    return totalUnits > 0 ? totalMinutes.toDouble() / totalUnits : 0.0;
  }
}
