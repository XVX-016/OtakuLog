import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/features/stats/models/wrapped_summary.dart';
import 'package:intl/intl.dart';

class StatsService {
  DateTime normalizedDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int calculateTotalMinutes(List<UserSessionEntity> sessions) {
    return sessions.fold(0, (sum, session) => sum + session.totalMinutes);
  }

  int calculateTotalUnits(
      List<UserSessionEntity> sessions, SessionContentType type) {
    return sessions
        .where((session) => session.contentType == type)
        .fold(0, (sum, session) => sum + session.unitsConsumed);
  }

  int calculateTodayMinutes(List<UserSessionEntity> sessions) {
    final today = normalizedDay(DateTime.now());
    return sessions
        .where((s) => !s.startTime.isBefore(today))
        .fold(0, (sum, s) => sum + s.totalMinutes);
  }

  int calculateStreak(List<UserSessionEntity> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    for (final date in dates) {
      if (date == current ||
          date == current.subtract(const Duration(days: 1))) {
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
    final last7Days = List.generate(
        7,
        (i) =>
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));

    final summary = <DateTime, int>{};
    for (final day in last7Days) {
      summary[day] = sessions
          .where((s) =>
              s.startTime.year == day.year &&
              s.startTime.month == day.month &&
              s.startTime.day == day.day)
          .fold(0, (sum, s) => sum + s.totalMinutes);
    }
    return summary;
  }

  Map<DateTime, int> calculateDailyTotals(
    List<UserSessionEntity> sessions, {
    int days = 90,
  }) {
    final now = DateTime.now();
    final summary = <DateTime, int>{};
    for (var i = 0; i < days; i++) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      summary[day] = sessions
          .where((s) =>
              s.startTime.year == day.year &&
              s.startTime.month == day.month &&
              s.startTime.day == day.day)
          .fold(0, (sum, s) => sum + s.totalMinutes);
    }
    return summary;
  }

  DateTime? calculateMostActiveDay(List<UserSessionEntity> sessions) {
    final dailyTotals = calculateDailyTotals(sessions, days: 3650);
    if (dailyTotals.isEmpty) return null;
    final sorted = dailyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value > 0 ? sorted.first.key : null;
  }

  int calculateLongestStreak(List<UserSessionEntity> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    var longest = 1;
    var current = 1;

    for (var i = 1; i < dates.length; i++) {
      final previous = dates[i - 1];
      final date = dates[i];
      final difference = date.difference(previous).inDays;
      if (difference == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (difference > 1) {
        current = 1;
      }
    }

    return longest;
  }

  double calculateAverageMinutesPerUnit(
      List<UserSessionEntity> sessions, SessionContentType type) {
    final filteredSessions =
        sessions.where((s) => s.contentType == type).toList();
    if (filteredSessions.isEmpty) return 0.0;
    final totalMinutes =
        filteredSessions.fold(0, (sum, s) => sum + s.totalMinutes);
    final totalUnits =
        filteredSessions.fold(0, (sum, s) => sum + s.unitsConsumed);
    return totalUnits > 0 ? totalMinutes.toDouble() / totalUnits : 0.0;
  }

  WrappedSummary generateWeeklyWrapped(
    List<UserSessionEntity> sessions,
    List<TrackableContent> library,
  ) {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final filtered = sessions
        .where((session) => !session.endTime.isBefore(periodStart))
        .toList();
    final week = int.parse(DateFormat('w').format(now));
    return _generateWrapped(
      periodType: WrappedPeriodType.weekly,
      periodKey: '${now.year}-W${week.toString().padLeft(2, '0')}',
      periodLabel: 'Last 7 days',
      title: 'Your Week in Anime',
      subtitle: 'A narrative snapshot of your last 7 days.',
      sessions: filtered,
      library: library,
      streak: calculateStreak(sessions),
    );
  }

  WrappedSummary generateMonthlyWrapped(
    List<UserSessionEntity> sessions,
    List<TrackableContent> library,
  ) {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final filtered = sessions
        .where((session) => !session.endTime.isBefore(periodStart))
        .toList();
    return _generateWrapped(
      periodType: WrappedPeriodType.monthly,
      periodKey: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      periodLabel: DateFormat('MMMM yyyy').format(now),
      title: 'Your Monthly Wrapped',
      subtitle: 'Your strongest habits over the last 30 days.',
      sessions: filtered,
      library: library,
      streak: calculateStreak(sessions),
    );
  }

  WrappedSummary _generateWrapped({
    required WrappedPeriodType periodType,
    required String periodKey,
    required String periodLabel,
    required String title,
    required String subtitle,
    required List<UserSessionEntity> sessions,
    required List<TrackableContent> library,
    required int streak,
  }) {
    final totalMinutes = calculateTotalMinutes(sessions);
    final totalEpisodes =
        calculateTotalUnits(sessions, SessionContentType.anime);
    final totalChapters =
        calculateTotalUnits(sessions, SessionContentType.manga);
    final sessionsCount = sessions.length;
    final libraryById = {for (final item in library) item.id: item};
    final minutesById = <String, int>{};
    final genreWeights = <String, int>{};

    for (final session in sessions) {
      minutesById.update(
          session.contentId, (value) => value + session.totalMinutes,
          ifAbsent: () => session.totalMinutes);
      final item = libraryById[session.contentId];
      if (item == null) continue;
      for (final genre in item.genres) {
        if (genre.trim().isEmpty) continue;
        genreWeights.update(genre, (value) => value + session.totalMinutes,
            ifAbsent: () => session.totalMinutes);
      }
    }

    final topAnime = _topTitle(minutesById, library, SessionContentType.anime);
    final topManga = _topTitle(minutesById, library, SessionContentType.manga);
    final topGenre = genreWeights.entries.isEmpty
        ? 'Still exploring'
        : (genreWeights.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    final mostActiveDay = calculateMostActiveDay(sessions);

    return WrappedSummary(
      periodType: periodType,
      periodKey: periodKey,
      periodLabel: periodLabel,
      title: title,
      subtitle: subtitle,
      headline: _headline(periodType, totalMinutes, streak),
      subheadline: _subheadline(topGenre, topAnime, topManga),
      totalMinutes: totalMinutes,
      totalEpisodes: totalEpisodes,
      totalChapters: totalChapters,
      topAnime: topAnime,
      topManga: topManga,
      topGenre: topGenre,
      streak: streak,
      mostActiveDay: mostActiveDay,
      sessionsCount: sessionsCount,
    );
  }

  String _topTitle(
    Map<String, int> minutesById,
    List<TrackableContent> library,
    SessionContentType type,
  ) {
    final filtered = minutesById.entries.where((entry) {
      TrackableContent? item;
      for (final element in library) {
        if (element.id == entry.key) {
          item = element;
          break;
        }
      }
      if (item == null) return false;
      return type == SessionContentType.anime
          ? item is AnimeEntity
          : item is MangaEntity;
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (filtered.isEmpty) {
      return type == SessionContentType.anime ? 'No anime yet' : 'No manga yet';
    }

    final id = filtered.first.key;
    for (final item in library) {
      final isType = type == SessionContentType.anime
          ? item is AnimeEntity
          : item is MangaEntity;
      if (isType && item.id == id) {
        return item.title;
      }
    }
    return 'Unknown title';
  }

  String _headline(WrappedPeriodType periodType, int totalMinutes, int streak) {
    final hours = (totalMinutes / 60).toStringAsFixed(1);
    if (periodType == WrappedPeriodType.weekly) {
      return totalMinutes > 0
          ? 'You spent $hours hours in your worlds this week.'
          : 'This week stayed quiet, but your next session can change that.';
    }
    return totalMinutes > 0
        ? 'You put in $hours hours this month and kept your habit moving.'
        : 'Your month is ready for a stronger comeback.';
  }

  String _subheadline(String topGenre, String topAnime, String topManga) {
    if (topGenre != 'Still exploring') {
      return '$topGenre led the way, with $topAnime and $topManga shaping your taste.';
    }
    return 'Your recent sessions are building a stronger taste profile.';
  }
}
