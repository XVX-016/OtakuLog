import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/domain/entities/anime.dart';

class AnimeMapper {
  static AnimeEntity toEntity(AnimeModel model) {
    return AnimeEntity(
      id: model.remoteId,
      title: model.title,
      coverImage: model.coverImage,
      totalEpisodes: model.totalEpisodes,
      currentEpisode: model.currentEpisode,
      status: _mapStatusToEntity(model.status),
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

  static AnimeStatus _mapStatusToEntity(AnimeStatusModel modelStatus) {
    switch (modelStatus) {
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

  static AnimeStatusModel _mapStatusToModel(AnimeStatus entityStatus) {
    switch (entityStatus) {
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
