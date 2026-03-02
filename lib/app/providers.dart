import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/data/local/isar_service.dart';
import 'package:goon_tracker/data/remote/anilist_service.dart';
import 'package:goon_tracker/data/remote/mangadex_service.dart';
import 'package:goon_tracker/data/repositories/anime_repository_impl.dart';
import 'package:goon_tracker/data/repositories/manga_repository_impl.dart';
import 'package:goon_tracker/data/repositories/search_repository_impl.dart';
import 'package:goon_tracker/data/repositories/session_repository_impl.dart';
import 'package:goon_tracker/domain/repositories/anime_repository.dart';
import 'package:goon_tracker/domain/repositories/manga_repository.dart';
import 'package:goon_tracker/domain/repositories/search_repository.dart';
import 'package:goon_tracker/domain/repositories/session_repository.dart';
import 'package:goon_tracker/domain/services/stats_service.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';

final isarProvider = Provider((ref) => IsarService.instance);

// Services
final anilistServiceProvider = Provider((ref) => AnilistService());
final mangadexServiceProvider = Provider((ref) => MangadexService());
final statsServiceProvider = Provider((ref) => StatsService());

// Repository Providers
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepositoryImpl(ref.watch(isarProvider));
});

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return MangaRepositoryImpl(ref.watch(isarProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(ref.watch(isarProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(
    anilistService: ref.watch(anilistServiceProvider),
    mangadexService: ref.watch(mangadexServiceProvider),
  );
});

final trendingAnimeProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(searchRepositoryProvider).getTrendingAnime();
});

final trendingMangaProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(searchRepositoryProvider).getTrendingManga();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(isarProvider));
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  return ref.watch(userRepositoryProvider).getUser();
});


