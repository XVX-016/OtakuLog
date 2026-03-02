import 'package:isar/isar.dart';
import 'package:goon_tracker/data/mappers/anime_mapper.dart';
import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/repositories/anime_repository.dart';

class AnimeRepositoryImpl implements AnimeRepository {
  final Isar isar;

  AnimeRepositoryImpl(this.isar);

  @override
  Future<List<AnimeEntity>> getAllAnime() async {
    final models = await isar.animeModels.where().findAll();
    return models.map(AnimeMapper.toEntity).toList();
  }

  @override
  Future<bool> saveAnime(AnimeEntity anime) async {
    try {
      await isar.writeTxn(() async {
        await isar.animeModels.put(AnimeMapper.toModel(anime));
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AnimeEntity?> getAnimeById(String id) async {
    final model = await isar.animeModels.filter().remoteIdEqualTo(id).findFirst();
    return model != null ? AnimeMapper.toEntity(model) : null;
  }

  @override
  Future<bool> deleteAnime(String id) async {
    try {
      return await isar.writeTxn(() async {
        final count = await isar.animeModels.filter().remoteIdEqualTo(id).deleteAll();
        return count > 0;
      });
    } catch (_) {
      return false;
    }
  }
}
