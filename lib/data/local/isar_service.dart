import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:goon_tracker/data/models/user_anime.dart';
import 'package:goon_tracker/data/models/user_manga.dart';
import 'package:goon_tracker/data/models/daily_activity.dart';

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserAnimeSchema,
        UserMangaSchema,
        DailyActivitySchema,
      ],
      directory: dir.path,
    );
  }
}
