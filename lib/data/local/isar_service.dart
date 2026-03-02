import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/data/models/manga_model.dart';
import 'package:goon_tracker/data/models/user_session_model.dart';
import 'package:goon_tracker/data/models/daily_activity.dart'; // Will be created next

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        AnimeModelSchema,
        MangaModelSchema,
        DailyActivitySchema,
        UserSessionModelSchema,
      ],
      directory: dir.path,
    );
  }
}
