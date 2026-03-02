import 'trackable_content.dart';

enum AnimeStatus { watching, completed, dropped, onHold }

class AnimeEntity implements TrackableContent {
  @override
  final String id;
  @override
  final String title;
  @override
  final String coverImage;
  
  final int totalEpisodes;
  final int currentEpisode;
  final AnimeStatus status;
  @override
  final double? rating;
  @override
  final List<String> genres;
  @override
  final String? description;
  
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  int get currentProgress => currentEpisode;
  @override
  int get totalProgress => totalEpisodes;

  AnimeEntity({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.status,
    this.rating,
    required this.genres,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  AnimeEntity copyWith({
    String? title,
    String? coverImage,
    int? totalEpisodes,
    int? currentEpisode,
    AnimeStatus? status,
    double? rating,
    DateTime? updatedAt,
  }) {
    return AnimeEntity(
      id: id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      genres: genres, // Typically doesn't change
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
