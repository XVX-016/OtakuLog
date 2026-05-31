import 'package:isar/isar.dart';
import 'package:otakulog/features/search/models/search_filters.dart';

part 'manga_model.g.dart';

@collection
class MangaModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String title;
  late String coverImage;
  late int totalChapters;
  late int currentChapter;

  @enumerated
  MangaCategoryFilter mangaCategory = MangaCategoryFilter.manga;

  @enumerated
  late MangaStatusModel status;

  double? rating;
  late List<String> genres;
  String? description;
  late bool isAdult;
  String? watchOrder;

  late DateTime createdAt;
  late DateTime updatedAt;
}

enum MangaStatusModel { reading, completed, dropped, onHold }
