import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/data/mappers/anime_mapper.dart';
import 'package:otakulog/data/mappers/manga_mapper.dart';
import 'package:otakulog/data/models/anime_model.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/data/remote/backup_mapper.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/services/recommendation_service.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';

void main() {
  group('Watch/Reading Order & Personal Notes Tests', () {
    test('AnimeEntity & MangaEntity copyWith preserves or updates watchOrder', () {
      final anime = AnimeEntity(
        id: '1',
        title: 'Monogatari',
        coverImage: 'cover',
        totalEpisodes: 12,
        currentEpisode: 0,
        status: AnimeStatus.watching,
        genres: ['Mystery'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        watchOrder: 'S1 -> S2',
      );

      expect(anime.watchOrder, 'S1 -> S2');

      final copiedAnime = anime.copyWith(watchOrder: 'New Order');
      expect(copiedAnime.watchOrder, 'New Order');
      expect(copiedAnime.title, 'Monogatari');

      final copiedAnimeNull = anime.copyWith(watchOrder: null);
      expect(copiedAnimeNull.watchOrder, 'S1 -> S2');

      final manga = MangaEntity(
        id: '1',
        title: 'One Piece',
        coverImage: 'cover',
        totalChapters: 1000,
        currentChapter: 0,
        status: MangaStatus.reading,
        genres: ['Adventure'],
        isAdult: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        watchOrder: 'Chapter 1-100',
      );

      expect(manga.watchOrder, 'Chapter 1-100');

      final copiedManga = manga.copyWith(watchOrder: 'Chapter 101-200');
      expect(copiedManga.watchOrder, 'Chapter 101-200');
    });

    test('AnimeMapper & MangaMapper toEntity/toModel maps watchOrder correctly', () {
      final model = AnimeModel()
        ..remoteId = '1'
        ..title = 'Monogatari'
        ..coverImage = 'cover'
        ..totalEpisodes = 12
        ..currentEpisode = 0
        ..status = AnimeStatusModel.watching
        ..genres = ['Mystery']
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..watchOrder = 'S1 -> Kizumonogatari';

      final entity = AnimeMapper.toEntity(model);
      expect(entity.watchOrder, 'S1 -> Kizumonogatari');

      final mappedModel = AnimeMapper.toModel(entity);
      expect(mappedModel.watchOrder, 'S1 -> Kizumonogatari');

      final mangaModel = MangaModel()
        ..remoteId = '1'
        ..title = 'Manga'
        ..coverImage = 'cover'
        ..totalChapters = 10
        ..currentChapter = 0
        ..status = MangaStatusModel.reading
        ..genres = ['Adventure']
        ..isAdult = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..watchOrder = 'Read order notes';

      final mangaEntity = MangaMapper.toEntity(mangaModel);
      expect(mangaEntity.watchOrder, 'Read order notes');

      final mappedMangaModel = MangaMapper.toModel(mangaEntity);
      expect(mappedMangaModel.watchOrder, 'Read order notes');
    });

    test('BackupMapper exportPayload/libraryFromPayload maps watchOrder', () {
      final anime = AnimeEntity(
        id: '1',
        title: 'Monogatari',
        coverImage: 'cover',
        totalEpisodes: 12,
        currentEpisode: 0,
        status: AnimeStatus.watching,
        genres: ['Mystery'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        watchOrder: 'S1 -> Kizumonogatari -> S2',
      );

      final mapper = BackupMapper();
      final payload = mapper.exportPayload(
        profile: null,
        library: [anime],
        sessions: [],
        retentionPreferences: const RetentionPreferences(),
      );

      expect(payload.library.first['watchOrder'], 'S1 -> Kizumonogatari -> S2');

      final importedList = mapper.libraryFromPayload(payload);
      expect(importedList.first.watchOrder, 'S1 -> Kizumonogatari -> S2');
    });

    test('PersonalizedRecommendation toJson/fromJson maps watchOrder', () {
      final anime = AnimeEntity(
        id: '1',
        title: 'Monogatari',
        coverImage: 'cover',
        totalEpisodes: 12,
        currentEpisode: 0,
        status: AnimeStatus.watching,
        genres: ['Mystery'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        watchOrder: 'S1 -> S2',
      );

      final recommendation = PersonalizedRecommendation(
        item: SearchResultItem(
          id: '1',
          content: anime,
          medium: SearchMedium.anime,
          tags: [],
          isAdult: false,
          inLibrary: true,
        ),
        score: 10.0,
        reason: 'Recommended',
      );

      final json = recommendation.toJson();
      final contentJson = json['item']['content'] as Map<String, dynamic>;
      expect(contentJson['watchOrder'], 'S1 -> S2');

      final decoded = PersonalizedRecommendation.fromJson(json);
      expect(decoded.item.content.watchOrder, 'S1 -> S2');
    });
  });
}
