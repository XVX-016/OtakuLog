enum GoalType { animeEpisodes, mangaChapters }

class GoalEntity {
  final String id;
  final GoalType goalType;
  final int targetValue;
  final int month;
  final int year;

  GoalEntity({
    required this.id,
    required this.goalType,
    required this.targetValue,
    required this.month,
    required this.year,
  });
}