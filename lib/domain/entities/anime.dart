class Anime {
  final int id;
  final int animeId;
  final String title;
  final int totalEpisodes;
  final int watchedEpisodes;
  final int durationPerEpisode;
  final double rating;
  final DateTime startedAt;
  final DateTime? completedAt;

  Anime({
    required this.id,
    required this.animeId,
    required this.title,
    required this.totalEpisodes,
    required this.watchedEpisodes,
    required this.durationPerEpisode,
    required this.rating,
    required this.startedAt,
    this.completedAt,
  });

  double get progress => totalEpisodes > 0 ? watchedEpisodes / totalEpisodes : 0.0;
  bool get isCompleted => watchedEpisodes >= totalEpisodes;
}
