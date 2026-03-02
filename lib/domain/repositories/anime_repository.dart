import 'package:goon_tracker/domain/entities/anime.dart';

abstract class AnimeRepository {
  Future<List<AnimeEntity>> getAllAnime();
  Future<void> saveAnime(AnimeEntity anime);
  Future<AnimeEntity?> getAnimeById(String id);
  Future<void> deleteAnime(String id);
}
