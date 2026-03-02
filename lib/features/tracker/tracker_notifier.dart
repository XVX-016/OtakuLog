import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';

class TrackerNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TrackerNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> logAnimeEpisode(AnimeEntity anime, int minutes) async {
    if (anime.currentEpisode >= anime.totalEpisodes) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      
      // 1. Create Session
      final session = UserSessionEntity(
        id: '0', // Isar auto-increment
        contentId: anime.id,
        contentType: SessionContentType.anime,
        startTime: now.subtract(Duration(minutes: minutes)),
        endTime: now,
        unitsConsumed: 1,
      );

      // 2. Save Session
      await ref.read(sessionRepositoryProvider).saveSession(session);

      // 3. Update Anime progress
      final updatedAnime = anime.copyWith(
        currentEpisode: anime.currentEpisode + 1,
        status: anime.currentEpisode + 1 == anime.totalEpisodes 
            ? AnimeStatus.completed 
            : AnimeStatus.watching,
        updatedAt: now,
      );
      await ref.read(animeRepositoryProvider).saveAnime(updatedAnime);
    });
  }

  Future<void> logMangaChapter(MangaEntity manga, int minutes) async {
    if (manga.currentChapter >= manga.totalChapters && manga.totalChapters != 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final now = DateTime.now();
      
      // 1. Create Session
      final session = UserSessionEntity(
        id: '0', 
        contentId: manga.id,
        contentType: SessionContentType.manga,
        startTime: now.subtract(Duration(minutes: minutes)),
        endTime: now,
        unitsConsumed: 1,
      );

      // 2. Save Session
      await ref.read(sessionRepositoryProvider).saveSession(session);

      // 3. Update Manga progress
      final updatedManga = manga.copyWith(
        currentChapter: manga.currentChapter + 1,
        status: (manga.totalChapters != 0 && manga.currentChapter + 1 == manga.totalChapters)
            ? MangaStatus.completed 
            : MangaStatus.reading,
        updatedAt: now,
      );
      await ref.read(mangaRepositoryProvider).saveManga(updatedManga);
    });
  }
}

final trackerNotifierProvider = StateNotifierProvider<TrackerNotifier, AsyncValue<void>>((ref) {
  return TrackerNotifier(ref);
});

final libraryAnimeProvider = FutureProvider<List<AnimeEntity>>((ref) {
  return ref.watch(animeRepositoryProvider).getAllAnime();
});

final libraryMangaProvider = FutureProvider<List<MangaEntity>>((ref) {
  return ref.watch(mangaRepositoryProvider).getAllManga();
});

final recentSessionsProvider = FutureProvider<List<UserSessionEntity>>((ref) {
  return ref.watch(sessionRepositoryProvider).getAllSessions();
});

final combinedLibraryProvider = FutureProvider<List<TrackableContent>>((ref) async {
  final animes = await ref.watch(libraryAnimeProvider.future);
  final mangas = await ref.watch(libraryMangaProvider.future);
  
  final combined = <TrackableContent>[...animes, ...mangas];
  // Sort by updatedAt descending
  combined.sort((a, b) {
    DateTime aTime = (a is AnimeEntity) ? a.updatedAt : (a as MangaEntity).updatedAt;
    DateTime bTime = (b is AnimeEntity) ? b.updatedAt : (b as MangaEntity).updatedAt;
    return bTime.compareTo(aTime);
  });
  
  return combined;
});
