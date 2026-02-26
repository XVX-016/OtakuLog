import 'package:goon_tracker/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<List<Manga>> getAllManga();
  Future<void> saveManga(Manga manga);
  Future<Manga?> getMangaById(String mangaId);
  Future<void> deleteManga(int id);
}
