import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  late String name;
  String? avatarPath;
  
  int defaultMangaReadTime = 15;
  int defaultAnimeWatchTime = 24;
  late String defaultSearchType;
  late String defaultContentRating;
  
  bool filter18Plus = false;
}
