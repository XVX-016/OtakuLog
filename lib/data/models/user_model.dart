import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  late String name;
  String? avatarPath;
  int avgMangaReadTime = 15;
  int avgAnimeWatchTime = 24;
  bool filter18Plus = false;
}
