import 'package:goon_tracker/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<List<MangaEntity>> getAllManga();
  Future<void> saveManga(MangaEntity manga);
  Future<MangaEntity?> getMangaById(String id);
  Future<void> deleteManga(String id);
}
