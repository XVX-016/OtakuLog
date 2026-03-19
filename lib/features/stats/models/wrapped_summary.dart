enum WrappedPeriodType { weekly, monthly }

class WrappedSummary {
  final WrappedPeriodType periodType;
  final String periodKey;
  final String periodLabel;
  final String title;
  final String subtitle;
  final String headline;
  final String subheadline;
  final int totalMinutes;
  final int totalEpisodes;
  final int totalChapters;
  final String topAnime;
  final String topManga;
  final String topGenre;
  final int streak;
  final DateTime? mostActiveDay;
  final int sessionsCount;

  const WrappedSummary({
    required this.periodType,
    required this.periodKey,
    required this.periodLabel,
    required this.title,
    required this.subtitle,
    required this.headline,
    required this.subheadline,
    required this.totalMinutes,
    required this.totalEpisodes,
    required this.totalChapters,
    required this.topAnime,
    required this.topManga,
    required this.topGenre,
    required this.streak,
    required this.mostActiveDay,
    required this.sessionsCount,
  });

  String get heroValue => (totalMinutes / 60).toStringAsFixed(1);
  String get heroLabel => 'hours tracked';
  String get dominantGenre => topGenre;
}
