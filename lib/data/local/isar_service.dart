import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otakulog/data/models/anime_model.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/data/models/user_session_model.dart';
import 'package:otakulog/data/models/user_model.dart';
import 'package:otakulog/data/models/daily_activity.dart';
import 'package:otakulog/data/models/achievement_model.dart';

class IsarService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        AnimeModelSchema,
        MangaModelSchema,
        UserModelSchema,
        DailyActivitySchema,
        UserSessionModelSchema,
        AchievementModelSchema,
      ],
      directory: dir.path,
    );
  }
}
