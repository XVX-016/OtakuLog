import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/data/local/isar_service.dart';
import 'package:goon_tracker/data/repositories/isar_anime_repository.dart';
import 'package:goon_tracker/data/repositories/isar_manga_repository.dart';
import 'package:goon_tracker/data/repositories/isar_tracker_repository.dart';
import 'package:goon_tracker/domain/repositories/anime_repository.dart';
import 'package:goon_tracker/domain/repositories/manga_repository.dart';
import 'package:goon_tracker/domain/repositories/tracker_repository.dart';

final isarProvider = Provider((ref) => IsarService.instance);

final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return IsarAnimeRepository(ref.watch(isarProvider));
});

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return IsarMangaRepository(ref.watch(isarProvider));
});

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  return IsarTrackerRepository(ref.watch(isarProvider));
});
