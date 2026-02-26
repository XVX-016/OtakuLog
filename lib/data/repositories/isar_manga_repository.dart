import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/user_manga.dart';
import 'package:goon_tracker/domain/repositories/manga_repository.dart';

class IsarMangaRepository implements MangaRepository {
  final Isar isar;

  IsarMangaRepository(this.isar);

  @override
  Future<List<UserManga>> getAllManga() {
    return isar.userMangas.where().findAll();
  }

  @override
  Future<void> saveManga(UserManga manga) async {
    await isar.writeTxn(() async {
      await isar.userMangas.put(manga);
    });
  }

  @override
  Future<UserManga?> getMangaById(String mangaId) {
    return isar.userMangas.filter().mangaIdEqualTo(mangaId).findFirst();
  }

  @override
  Future<void> deleteManga(int id) async {
    await isar.writeTxn(() async {
      await isar.userMangas.delete(id);
    });
  }
}
