import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/data/local/isar_service.dart';
import 'package:goon_tracker/data/remote/anilist_service.dart';
import 'package:goon_tracker/data/remote/mangadex_service.dart';
import 'package:goon_tracker/data/repositories/anime_repository_impl.dart';
import 'package:goon_tracker/data/repositories/manga_repository_impl.dart';
import 'package:goon_tracker/data/repositories/session_repository_impl.dart';
import 'package:goon_tracker/data/repositories/isar_tracker_repository.dart';
import 'package:goon_tracker/data/repositories/user_repository_impl.dart';
import 'package:goon_tracker/data/repositories/search_repository_impl.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/repositories/anime_repository.dart';
import 'package:goon_tracker/domain/repositories/manga_repository.dart';
import 'package:goon_tracker/domain/repositories/session_repository.dart';
import 'package:goon_tracker/domain/repositories/tracker_repository.dart';
import 'package:goon_tracker/domain/repositories/user_repository.dart';
import 'package:goon_tracker/domain/repositories/search_repository.dart';
import 'package:goon_tracker/domain/services/stats_service.dart';

// Services
final anilistServiceProvider = Provider<AnilistService>((ref) => AnilistService());
final mangadexServiceProvider = Provider<MangadexService>((ref) => MangadexService());
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

// Repositories
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepositoryImpl(IsarService.instance);
});

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return MangaRepositoryImpl(IsarService.instance);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(IsarService.instance);
});

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  return IsarTrackerRepository(IsarService.instance);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(IsarService.instance);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final anilist = ref.watch(anilistServiceProvider);
  final mangadex = ref.watch(mangadexServiceProvider);
  return SearchRepositoryImpl(
    anilistService: anilist,
    mangadexService: mangadex,
  );
});

// Domain Providers
final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  return ref.watch(userRepositoryProvider).getUser('local_user');
});

final trendingAnimeProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(searchRepositoryProvider).getTrendingAnime();
});

final recentSessionsProvider = FutureProvider<List<UserSessionEntity>>((ref) {
  return ref.watch(sessionRepositoryProvider).getRecentSessions();
});

final libraryAnimeProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(animeRepositoryProvider).getAllAnime();
});

final libraryMangaProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(mangaRepositoryProvider).getAllManga();
});

final combinedLibraryProvider = FutureProvider<List<TrackableContent>>((ref) async {
  final anime = await ref.watch(libraryAnimeProvider.future);
  final manga = await ref.watch(libraryMangaProvider.future);
  final combined = [...anime, ...manga];
  combined.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return combined;
});
