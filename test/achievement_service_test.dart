import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:otakulog/data/models/achievement_model.dart';
import 'package:otakulog/data/models/anime_model.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/data/models/user_session_model.dart';
import 'package:otakulog/domain/entities/achievement.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/achievement_service.dart';

void main() {
  late Isar isar;
  late AchievementService achievementService;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [
        AchievementModelSchema,
        AnimeModelSchema,
        MangaModelSchema,
        UserSessionModelSchema,
      ],
      directory: (await Directory.systemTemp.createTemp()).path,
    );
    achievementService = AchievementService(isar);
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
  });

  setUp(() async {
    await isar.writeTxn(() async {
      await isar.achievementModels.clear();
    });
  });

  group('AchievementService Tests', () {
    final now = DateTime.now();

    test('calculateProgress should return correct counts', () {
      final library = <TrackableContent>[
        AnimeEntity(
          id: 'a1',
          title: 'Anime 1',
          coverImage: '',
          totalEpisodes: 12,
          currentEpisode: 12,
          status: AnimeStatus.completed,
          genres: [],
          createdAt: now,
          updatedAt: now,
        ),
        MangaEntity(
          id: 'm1',
          title: 'Manga 1',
          coverImage: '',
          totalChapters: 10,
          currentChapter: 5,
          status: MangaStatus.reading,
          genres: [],
          isAdult: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sessions = [
        UserSessionEntity(
          id: 's1',
          contentId: 'a1',
          contentType: SessionContentType.anime,
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.subtract(const Duration(hours: 1)),
          unitsConsumed: 12,
        ),
        UserSessionEntity(
          id: 's2',
          contentId: 'm1',
          contentType: SessionContentType.manga,
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now,
          unitsConsumed: 5,
        ),
      ];

      // First Anime Completed
      final defFirstAnime = achievementDefinitions.firstWhere((d) => d.id == 'first_anime_completed');
      expect(achievementService.calculateProgress(defFirstAnime, library, sessions), 1);

      // First Manga Completed (should be 0 since status is reading)
      final defFirstManga = achievementDefinitions.firstWhere((d) => d.id == 'first_manga_completed');
      expect(achievementService.calculateProgress(defFirstManga, library, sessions), 0);

      // Episode watched threshold
      final defEpisodes = achievementDefinitions.firstWhere((d) => d.id == '100_episodes_watched');
      expect(achievementService.calculateProgress(defEpisodes, library, sessions), 12);

      // Chapter read threshold
      final defChapters = achievementDefinitions.firstWhere((d) => d.id == '500_chapters_read');
      expect(achievementService.calculateProgress(defChapters, library, sessions), 5);

      // Anime logged count
      final defAnimeLogged = achievementDefinitions.firstWhere((d) => d.id == '50_anime_logged');
      expect(achievementService.calculateProgress(defAnimeLogged, library, sessions), 1);

      // Manga logged count
      final defMangaLogged = achievementDefinitions.firstWhere((d) => d.id == '25_manga_logged');
      expect(achievementService.calculateProgress(defMangaLogged, library, sessions), 1);
    });

    test('evaluateAchievements unlocks new achievements and avoids duplicates', () async {
      final library = <TrackableContent>[
        AnimeEntity(
          id: 'a1',
          title: 'Anime 1',
          coverImage: '',
          totalEpisodes: 12,
          currentEpisode: 12,
          status: AnimeStatus.completed,
          genres: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final sessions = <UserSessionEntity>[];

      // 1. Evaluate - should unlock first_anime_completed
      final newlyUnlocked = await achievementService.evaluateAchievements(
        library: library,
        sessions: sessions,
      );

      expect(newlyUnlocked.length, 1);
      expect(newlyUnlocked.first.id, 'first_anime_completed');

      // Check DB persistence
      final unlockedInDb = await achievementService.getUnlockedAchievements();
      expect(unlockedInDb.length, 1);
      expect(unlockedInDb.first.id, 'first_anime_completed');

      // 2. Evaluate again with same data - should not unlock anything new
      final reEvaluate = await achievementService.evaluateAchievements(
        library: library,
        sessions: sessions,
      );
      expect(reEvaluate.isEmpty, true);

      final finalDbList = await achievementService.getUnlockedAchievements();
      expect(finalDbList.length, 1);
    });

    test('retroactive unlock unlocks previously earned milestones', () async {
      final library = <TrackableContent>[
        AnimeEntity(
          id: 'a1',
          title: 'Anime 1',
          coverImage: '',
          totalEpisodes: 12,
          currentEpisode: 12,
          status: AnimeStatus.completed,
          genres: [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sessions = List.generate(
        100,
        (i) => UserSessionEntity(
          id: 's$i',
          contentId: 'a1',
          contentType: SessionContentType.anime,
          startTime: now.subtract(Duration(days: 100 - i)),
          endTime: now.subtract(Duration(days: 100 - i, minutes: -30)),
          unitsConsumed: 1,
        ),
      );

      // Retroactive unlock evaluates current totals
      final unlocked = await achievementService.performRetroactiveUnlock(
        library: library,
        sessions: sessions,
      );

      // Should unlock: first_anime_completed, 100_episodes_watched, 7-day, 30-day, 100-day streaks
      final unlockedIds = unlocked.map((a) => a.id).toSet();
      expect(unlockedIds.contains('first_anime_completed'), true);
      expect(unlockedIds.contains('100_episodes_watched'), true);
      expect(unlockedIds.contains('7_day_streak'), true);
      expect(unlockedIds.contains('30_day_streak'), true);
      expect(unlockedIds.contains('100_day_streak'), true);
    });
  });
}
