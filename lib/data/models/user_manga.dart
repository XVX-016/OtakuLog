import 'package:isar/isar.dart';
import 'package:goon_tracker/domain/entities/manga.dart';

part 'user_manga.g.dart';

@collection
class UserManga {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String mangaId;

  late String title;
  late int totalChapters;
  late int readChapters;
  int? totalVolumes;
  late int readVolumes;
  late double rating;
  late DateTime startedAt;
  DateTime? completedAt;

  Manga toEntity() => Manga(
        id: id,
        mangaId: int.parse(mangaId), // Assuming mangaId is int-like string for Anilist/MangaDex
        title: title,
        totalChapters: totalChapters,
        readChapters: readChapters,
        totalVolumes: totalVolumes,
        readVolumes: readVolumes,
        rating: rating,
        startedAt: startedAt,
        completedAt: completedAt,
      );

  static UserManga fromEntity(Manga entity) => UserManga()
    ..id = entity.id
    ..mangaId = entity.mangaId.toString()
    ..title = entity.title
    ..totalChapters = entity.totalChapters
    ..readChapters = entity.readChapters
    ..totalVolumes = entity.totalVolumes
    ..readVolumes = entity.readVolumes
    ..rating = entity.rating
    ..startedAt = entity.startedAt
    ..completedAt = entity.completedAt;
}
