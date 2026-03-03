import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/data/repositories/anime_repository_impl.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  late Isar isar;
  late AnimeRepositoryImpl repository;

  setUpAll(() async {
    // Note: Integration tests with Isar in unit test environment can be tricky
    // as it requires the native library. We use a temporary directory.
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [AnimeModelSchema],
      directory: (await Directory.systemTemp.createTemp()).path,
    );
    repository = AnimeRepositoryImpl(isar);
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('AnimeRepository Integration Tests', () {
    test('Saving and retrieving AnimeEntity should maintain data integrity', () async {
      final anime = AnimeEntity(
        id: '123',
        title: 'Test Anime',
        coverImage: 'url',
        totalEpisodes: 12,
        currentEpisode: 0,
        status: AnimeStatus.watching,
        genres: ['Action', 'Sci-Fi'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.saveAnime(anime);
      final retrieved = await repository.getAnimeById('123');

      expect(retrieved?.title, 'Test Anime');
      expect(retrieved?.id, '123');
      expect(retrieved?.totalEpisodes, 12);
    });
  });
}
