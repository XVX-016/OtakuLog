import 'package:isar/isar.dart';
import 'package:goon_tracker/data/mappers/manga_mapper.dart';
import 'package:goon_tracker/data/models/manga_model.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/repositories/manga_repository.dart';

class MangaRepositoryImpl implements MangaRepository {
  final Isar isar;

  MangaRepositoryImpl(this.isar);

  @override
  Future<List<MangaEntity>> getAllManga() async {
    final models = await isar.mangaModels.where().findAll();
    return models.map(MangaMapper.toEntity).toList();
  }

  @override
  Future<void> saveManga(MangaEntity manga) async {
    await isar.writeTxn(() async {
      await isar.mangaModels.put(MangaMapper.toModel(manga));
    });
  }

  @override
  Future<MangaEntity?> getMangaById(String id) async {
    final model = await isar.mangaModels.filter().remoteIdEqualTo(id).findFirst();
    return model != null ? MangaMapper.toEntity(model) : null;
  }

  @override
  Future<void> deleteManga(String id) async {
    await isar.writeTxn(() async {
      await isar.mangaModels.filter().remoteIdEqualTo(id).deleteAll();
    });
  }
}
