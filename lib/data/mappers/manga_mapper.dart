import 'package:goon_tracker/data/models/manga_model.dart';
import 'package:goon_tracker/domain/entities/manga.dart';

class MangaMapper {
  static MangaEntity toEntity(MangaModel model) {
    return MangaEntity(
      id: model.remoteId,
      title: model.title,
      coverImage: model.coverImage,
      totalChapters: model.totalChapters,
      currentChapter: model.currentChapter,
      status: _mapStatusToEntity(model.status),
      rating: model.rating,
      genres: model.genres,
      description: model.description,
      isAdult: model.isAdult,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static MangaModel toModel(MangaEntity entity) {
    return MangaModel()
      ..remoteId = entity.id
      ..title = entity.title
      ..coverImage = entity.coverImage
      ..totalChapters = entity.totalChapters
      ..currentChapter = entity.currentChapter
      ..status = _mapStatusToModel(entity.status)
      ..rating = entity.rating
      ..genres = entity.genres
      ..description = entity.description
      ..isAdult = entity.isAdult
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }

  static MangaStatus _mapStatusToEntity(MangaStatusModel modelStatus) {
    switch (modelStatus) {
      case MangaStatusModel.reading:
        return MangaStatus.reading;
      case MangaStatusModel.completed:
        return MangaStatus.completed;
      case MangaStatusModel.dropped:
        return MangaStatus.dropped;
      case MangaStatusModel.onHold:
        return MangaStatus.onHold;
    }
  }

  static MangaStatusModel _mapStatusToModel(MangaStatus entityStatus) {
    switch (entityStatus) {
      case MangaStatus.reading:
        return MangaStatusModel.reading;
      case MangaStatus.completed:
        return MangaStatusModel.completed;
      case MangaStatus.dropped:
        return MangaStatusModel.dropped;
      case MangaStatus.onHold:
        return MangaStatusModel.onHold;
    }
  }
}
