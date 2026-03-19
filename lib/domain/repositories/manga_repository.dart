import 'package:otakulog/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<List<MangaEntity>> getAllManga();
  Future<bool> saveManga(MangaEntity manga);
  Future<MangaEntity?> getMangaById(String id);
  Future<bool> deleteManga(String id);
}
