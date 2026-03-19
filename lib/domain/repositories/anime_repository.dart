import 'package:otakulog/domain/entities/anime.dart';

abstract class AnimeRepository {
  Future<List<AnimeEntity>> getAllAnime();
  Future<bool> saveAnime(AnimeEntity anime);
  Future<AnimeEntity?> getAnimeById(String id);
  Future<bool> deleteAnime(String id);
}
