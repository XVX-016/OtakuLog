import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/user_anime.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/repositories/anime_repository.dart';

class IsarAnimeRepository implements AnimeRepository {
  final Isar isar;

  IsarAnimeRepository(this.isar);

  @override
  Future<List<Anime>> getAllAnime() async {
    final result = await isar.userAnimes.where().findAll();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveAnime(Anime anime) async {
    await isar.writeTxn(() async {
      await isar.userAnimes.put(UserAnime.fromEntity(anime));
    });
  }

  @override
  Future<Anime?> getAnimeById(int animeId) async {
    final result = await isar.userAnimes.filter().animeIdEqualTo(animeId).findFirst();
    return result?.toEntity();
  }

  @override
  Future<void> deleteAnime(int id) async {
    await isar.writeTxn(() async {
      await isar.userAnimes.delete(id);
    });
  }
}
