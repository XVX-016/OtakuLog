class Manga {
  final int id;
  final int mangaId;
  final String title;
  final int totalChapters;
  final int readChapters;
  final int? totalVolumes;
  final int readVolumes;
  final double rating;
  final DateTime startedAt;
  final DateTime? completedAt;

  Manga({
    required this.id,
    required this.mangaId,
    required this.title,
    required this.totalChapters,
    required this.readChapters,
    this.totalVolumes,
    required this.readVolumes,
    required this.rating,
    required this.startedAt,
    this.completedAt,
  });

  double get progress => totalChapters > 0 ? readChapters / totalChapters : 0.0;
  bool get isCompleted => readChapters >= totalChapters;
}
