import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/domain/entities/anime.dart';

class AnimeMapper {
  static AnimeEntity fromJson(Map<String, dynamic> json) {
    final titleData = json['title'] as Map? ?? {};
    final resolvedTitle = titleData['english'] ?? titleData['romaji'] ?? titleData['native'] ?? 'Unknown';

    final coverImage = json['coverImage'] as Map? ?? {};
    final largeCover = coverImage['large'] ?? '';

    final genres = List<String>.from(json['genres'] ?? []);
    
    // Defensive numeric parsing
    final averageScore = json['averageScore'];
    double? rating;
    if (averageScore != null) {
      if (averageScore is num) {
        rating = averageScore.toDouble() / 10.0;
      }
    }

    final updatedAtTimestamp = json['updatedAt'] as int? ?? 0;
    final updatedAt = updatedAtTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtTimestamp * 1000)
        : DateTime.now();

    return AnimeEntity(
      id: (json['id'] ?? '').toString(),
      title: resolvedTitle,
      coverImage: largeCover,
      totalEpisodes: json['episodes'] ?? 0,
      currentEpisode: 0,
      status: AnimeStatus.watching,
      rating: rating,
      genres: genres,
      description: json['description'],
      createdAt: DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  static AnimeEntity toEntity(AnimeModel model) {
    return AnimeEntity(
      id: model.remoteId,
      title: model.title,
      coverImage: model.coverImage,
      totalEpisodes: model.totalEpisodes,
      currentEpisode: model.currentEpisode,
      status: _mapStatusFromModel(model.status),
      rating: model.rating,
      genres: model.genres,
      description: model.description,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static AnimeModel toModel(AnimeEntity entity) {
    return AnimeModel()
      ..remoteId = entity.id
      ..title = entity.title
      ..coverImage = entity.coverImage
      ..totalEpisodes = entity.totalEpisodes
      ..currentEpisode = entity.currentEpisode
      ..status = _mapStatusToModel(entity.status)
      ..rating = entity.rating
      ..genres = entity.genres
      ..description = entity.description
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }

  static AnimeStatus _mapStatusFromModel(AnimeStatusModel model) {
    switch (model) {
      case AnimeStatusModel.watching:
        return AnimeStatus.watching;
      case AnimeStatusModel.completed:
        return AnimeStatus.completed;
      case AnimeStatusModel.dropped:
        return AnimeStatus.dropped;
      case AnimeStatusModel.onHold:
        return AnimeStatus.onHold;
    }
  }

  static AnimeStatusModel _mapStatusToModel(AnimeStatus status) {
    switch (status) {
      case AnimeStatus.watching:
        return AnimeStatusModel.watching;
      case AnimeStatus.completed:
        return AnimeStatusModel.completed;
      case AnimeStatus.dropped:
        return AnimeStatusModel.dropped;
      case AnimeStatus.onHold:
        return AnimeStatusModel.onHold;
    }
  }
}
