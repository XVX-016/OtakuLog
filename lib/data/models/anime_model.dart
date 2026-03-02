import 'package:isar/isar.dart';

part 'anime_model.g.dart';

@collection
class AnimeModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  late String title;
  
  late String coverImage;
  
  late int totalEpisodes;
  
  late int currentEpisode;

  @enumerated
  late AnimeStatusModel status;
  
  double? rating;
  
  late DateTime createdAt;
  
  late DateTime updatedAt;
}

enum AnimeStatusModel { watching, completed, dropped, onHold }
