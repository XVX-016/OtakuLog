import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String localId;

  late String name;
  String? avatarPath;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String defaultSearchType;
  late String defaultContentRating;
  late int defaultAnimeWatchTime;
  late int defaultMangaReadTime;
  late bool filter18Plus;
}
