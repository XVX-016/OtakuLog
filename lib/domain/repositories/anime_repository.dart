import 'package:goon_tracker/domain/entities/anime.dart';

abstract class AnimeRepository {
  Future<List<Anime>> getAllAnime();
  Future<void> saveAnime(Anime anime);
  Future<Anime?> getAnimeById(int animeId);
  Future<void> deleteAnime(int id);
}
