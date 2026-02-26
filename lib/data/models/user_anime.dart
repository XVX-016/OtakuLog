import 'package:isar/isar.dart';
import 'package:goon_tracker/domain/entities/anime.dart';

part 'user_anime.g.dart';

@collection
class UserAnime {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late int animeId;

  late String title;
  late int totalEpisodes;
  late int watchedEpisodes;
  late int durationPerEpisode; // in minutes
  late double rating;
  late DateTime startedAt;
  DateTime? completedAt;

  Anime toEntity() => Anime(
        id: id,
        animeId: animeId,
        title: title,
        totalEpisodes: totalEpisodes,
        watchedEpisodes: watchedEpisodes,
        durationPerEpisode: durationPerEpisode,
        rating: rating,
        startedAt: startedAt,
        completedAt: completedAt,
      );

  static UserAnime fromEntity(Anime entity) => UserAnime()
    ..id = entity.id
    ..animeId = entity.animeId
    ..title = entity.title
    ..totalEpisodes = entity.totalEpisodes
    ..watchedEpisodes = entity.watchedEpisodes
    ..durationPerEpisode = entity.durationPerEpisode
    ..rating = entity.rating
    ..startedAt = entity.startedAt
    ..completedAt = entity.completedAt;
}
