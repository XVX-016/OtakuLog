import 'package:otakulog/data/models/achievement_model.dart';
import 'package:otakulog/domain/entities/achievement.dart';

class AchievementMapper {
  static AchievementType toEntityEnum(AchievementTypeModel modelType) {
    switch (modelType) {
      case AchievementTypeModel.firstAnimeCompleted:
        return AchievementType.firstAnimeCompleted;
      case AchievementTypeModel.firstMangaCompleted:
        return AchievementType.firstMangaCompleted;
      case AchievementTypeModel.episodesWatchedThreshold:
        return AchievementType.episodesWatchedThreshold;
      case AchievementTypeModel.chaptersReadThreshold:
        return AchievementType.chaptersReadThreshold;
      case AchievementTypeModel.streakThreshold:
        return AchievementType.streakThreshold;
      case AchievementTypeModel.animeLoggedThreshold:
        return AchievementType.animeLoggedThreshold;
      case AchievementTypeModel.mangaLoggedThreshold:
        return AchievementType.mangaLoggedThreshold;
    }
  }

  static AchievementTypeModel toModelEnum(AchievementType entityType) {
    switch (entityType) {
      case AchievementType.firstAnimeCompleted:
        return AchievementTypeModel.firstAnimeCompleted;
      case AchievementType.firstMangaCompleted:
        return AchievementTypeModel.firstMangaCompleted;
      case AchievementType.episodesWatchedThreshold:
        return AchievementTypeModel.episodesWatchedThreshold;
      case AchievementType.chaptersReadThreshold:
        return AchievementTypeModel.chaptersReadThreshold;
      case AchievementType.streakThreshold:
        return AchievementTypeModel.streakThreshold;
      case AchievementType.animeLoggedThreshold:
        return AchievementTypeModel.animeLoggedThreshold;
      case AchievementType.mangaLoggedThreshold:
        return AchievementTypeModel.mangaLoggedThreshold;
    }
  }

  static AchievementEntity toEntity(AchievementModel model) {
    return AchievementEntity(
      id: model.id,
      type: toEntityEnum(model.type),
      unlockedAt: model.unlockedAt,
    );
  }

  static AchievementModel toModel(AchievementEntity entity) {
    return AchievementModel()
      ..id = entity.id
      ..type = toModelEnum(entity.type)
      ..unlockedAt = entity.unlockedAt;
  }
}
