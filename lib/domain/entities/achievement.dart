enum AchievementType {
  firstAnimeCompleted,
  firstMangaCompleted,
  episodesWatchedThreshold,
  chaptersReadThreshold,
  streakThreshold,
  animeLoggedThreshold,
  mangaLoggedThreshold,
}

class AchievementEntity {
  final String id;
  final AchievementType type;
  final DateTime unlockedAt;

  const AchievementEntity({
    required this.id,
    required this.type,
    required this.unlockedAt,
  });
}

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int threshold;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
  });
}

const List<AchievementDefinition> achievementDefinitions = [
  AchievementDefinition(
    id: 'first_anime_completed',
    title: 'First Anime Completed',
    description: 'Complete your first anime series',
    type: AchievementType.firstAnimeCompleted,
    threshold: 1,
  ),
  AchievementDefinition(
    id: 'first_manga_completed',
    title: 'First Manga Completed',
    description: 'Complete your first manga series',
    type: AchievementType.firstMangaCompleted,
    threshold: 1,
  ),
  AchievementDefinition(
    id: '100_episodes_watched',
    title: '100 Episodes Watched',
    description: 'Watch a total of 100 episodes',
    type: AchievementType.episodesWatchedThreshold,
    threshold: 100,
  ),
  AchievementDefinition(
    id: '500_chapters_read',
    title: '500 Chapters Read',
    description: 'Read a total of 500 chapters',
    type: AchievementType.chaptersReadThreshold,
    threshold: 500,
  ),
  AchievementDefinition(
    id: '7_day_streak',
    title: '7-Day Streak',
    description: 'Maintain a logging streak of 7 days',
    type: AchievementType.streakThreshold,
    threshold: 7,
  ),
  AchievementDefinition(
    id: '30_day_streak',
    title: '30-Day Streak',
    description: 'Maintain a logging streak of 30 days',
    type: AchievementType.streakThreshold,
    threshold: 30,
  ),
  AchievementDefinition(
    id: '100_day_streak',
    title: '100-Day Streak',
    description: 'Maintain a logging streak of 100 days',
    type: AchievementType.streakThreshold,
    threshold: 100,
  ),
  AchievementDefinition(
    id: '50_anime_logged',
    title: '50 Anime Logged',
    description: 'Add 50 anime to your library',
    type: AchievementType.animeLoggedThreshold,
    threshold: 50,
  ),
  AchievementDefinition(
    id: '25_manga_logged',
    title: '25 Manga Logged',
    description: 'Add 25 manga to your library',
    type: AchievementType.mangaLoggedThreshold,
    threshold: 25,
  ),
];
