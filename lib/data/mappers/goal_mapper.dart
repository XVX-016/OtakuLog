import 'package:otakulog/data/models/goal_model.dart';
import 'package:otakulog/domain/entities/goal.dart';

class GoalMapper {
  static GoalEntity toEntity(GoalModel model) {
    return GoalEntity(
      id: model.id.toString(),
      goalType: model.goalType == 'animeEpisodes'
          ? GoalType.animeEpisodes
          : GoalType.mangaChapters,
      targetValue: model.targetValue,
      month: model.month,
      year: model.year,
    );
  }

  static GoalModel toModel(GoalEntity entity) {
    final model = GoalModel();

    model.goalType = entity.goalType.name;
    model.targetValue = entity.targetValue;
    model.month = entity.month;
    model.year = entity.year;

    return model;
  }
}