import 'package:isar/isar.dart';
import 'package:otakulog/data/mappers/achievement_mapper.dart';
import 'package:otakulog/data/models/achievement_model.dart';
import 'package:otakulog/domain/entities/achievement.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/stats_service.dart';

class AchievementService {
  final Isar _isar;
  final StatsService _statsService = StatsService();

  AchievementService(this._isar);

  Future<List<AchievementEntity>> getUnlockedAchievements() async {
    final models = await _isar.achievementModels.where().findAll();
    return models.map(AchievementMapper.toEntity).toList();
  }

  int calculateProgress(
    AchievementDefinition def,
    List<TrackableContent> library,
    List<UserSessionEntity> sessions,
  ) {
    switch (def.type) {
      case AchievementType.firstAnimeCompleted:
        final completedAnime = library
            .whereType<AnimeEntity>()
            .where((a) => a.status == AnimeStatus.completed)
            .length;
        return completedAnime >= 1 ? 1 : 0;
      case AchievementType.firstMangaCompleted:
        final completedManga = library
            .whereType<MangaEntity>()
            .where((m) => m.status == MangaStatus.completed)
            .length;
        return completedManga >= 1 ? 1 : 0;
      case AchievementType.episodesWatchedThreshold:
        return sessions
            .where((s) => s.contentType == SessionContentType.anime)
            .fold(0, (sum, s) => sum + s.unitsConsumed);
      case AchievementType.chaptersReadThreshold:
        return sessions
            .where((s) => s.contentType == SessionContentType.manga)
            .fold(0, (sum, s) => sum + s.unitsConsumed);
      case AchievementType.streakThreshold:
        return _statsService.calculateLongestStreak(sessions);
      case AchievementType.animeLoggedThreshold:
        return library.whereType<AnimeEntity>().length;
      case AchievementType.mangaLoggedThreshold:
        return library.whereType<MangaEntity>().length;
    }
  }

  Future<List<AchievementEntity>> evaluateAchievements({
    required List<TrackableContent> library,
    required List<UserSessionEntity> sessions,
  }) async {
    final existingModels = await _isar.achievementModels.where().findAll();
    final unlockedIds = existingModels.map((m) => m.id).toSet();

    final newlyUnlocked = <AchievementEntity>[];
    final now = DateTime.now();

    for (final def in achievementDefinitions) {
      if (unlockedIds.contains(def.id)) continue;

      final progress = calculateProgress(def, library, sessions);
      if (progress >= def.threshold) {
        final entity = AchievementEntity(
          id: def.id,
          type: def.type,
          unlockedAt: now,
        );
        final model = AchievementMapper.toModel(entity);
        await _isar.writeTxn(() async {
          await _isar.achievementModels.put(model);
        });
        newlyUnlocked.add(entity);
      }
    }
    return newlyUnlocked;
  }

  Future<List<AchievementEntity>> performRetroactiveUnlock({
    required List<TrackableContent> library,
    required List<UserSessionEntity> sessions,
  }) async {
    return evaluateAchievements(library: library, sessions: sessions);
  }
}
