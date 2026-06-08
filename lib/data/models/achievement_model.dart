import 'package:isar/isar.dart';

part 'achievement_model.g.dart';

@collection
class AchievementModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @enumerated
  late AchievementTypeModel type;

  late DateTime unlockedAt;
}

enum AchievementTypeModel {
  firstAnimeCompleted,
  firstMangaCompleted,
  episodesWatchedThreshold,
  chaptersReadThreshold,
  streakThreshold,
  animeLoggedThreshold,
  mangaLoggedThreshold,
}
