import 'package:isar/isar.dart';
import 'package:otakulog/data/mappers/manga_mapper.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/repositories/manga_repository.dart';

class MangaRepositoryImpl implements MangaRepository {
  final Isar isar;

  MangaRepositoryImpl(this.isar);

  @override
  Future<List<MangaEntity>> getAllManga() async {
    final models = await isar.mangaModels.where().findAll();
    return models.map(MangaMapper.toEntity).toList();
  }

  @override
  Future<bool> saveManga(MangaEntity manga) async {
    try {
      await isar.writeTxn(() async {
        await isar.mangaModels.put(MangaMapper.toModel(manga));
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<MangaEntity?> getMangaById(String id) async {
    final model = await isar.mangaModels.filter().remoteIdEqualTo(id).findFirst();
    return model != null ? MangaMapper.toEntity(model) : null;
  }

  @override
  Future<bool> deleteManga(String id) async {
    try {
      return await isar.writeTxn(() async {
        final count = await isar.mangaModels.filter().remoteIdEqualTo(id).deleteAll();
        return count > 0;
      });
    } catch (_) {
      return false;
    }
  }
}
