import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/data/models/user_anime.dart';
import 'package:goon_tracker/data/models/user_manga.dart';

class TrackerNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  TrackerNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> addAnime({
    required int animeId,
    required String title,
    required int totalEpisodes,
    required int durationPerEpisode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final anime = UserAnime()
        ..animeId = animeId
        ..title = title
        ..totalEpisodes = totalEpisodes
        ..watchedEpisodes = 0
        ..durationPerEpisode = durationPerEpisode
        ..rating = 0.0
        ..startedAt = DateTime.now();

      await ref.read(animeRepositoryProvider).saveAnime(anime);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logEpisode(UserAnime anime) async {
    if (anime.watchedEpisodes >= anime.totalEpisodes) return;

    state = const AsyncValue.loading();
    try {
      anime.watchedEpisodes++;
      if (anime.watchedEpisodes == anime.totalEpisodes) {
        anime.completedAt = DateTime.now();
      }
      
      await ref.read(animeRepositoryProvider).saveAnime(anime);
      await ref.read(trackerRepositoryProvider).logActivity(
        DateTime.now(),
        minutesWatched: anime.durationPerEpisode,
      );
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Manga methods can be added here as well
}

final trackerNotifierProvider = StateNotifierProvider<TrackerNotifier, AsyncValue<void>>((ref) {
  return TrackerNotifier(ref);
});

final userAnimeListProvider = FutureProvider<List<UserAnime>>((ref) {
  return ref.watch(animeRepositoryProvider).getAllAnime();
});

final dailyActivityProvider = FutureProvider((ref) {
  return ref.watch(trackerRepositoryProvider).getRecentActivity(7);
});
