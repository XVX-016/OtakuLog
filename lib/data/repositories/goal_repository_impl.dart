import 'package:isar/isar.dart';
import 'package:otakulog/data/mappers/goal_mapper.dart';
import 'package:otakulog/domain/entities/goal.dart';
import 'package:otakulog/domain/repositories/goal_repository.dart';
import 'package:otakulog/data/models/goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  final Isar isar;

  GoalRepositoryImpl(this.isar);

  @override
  Future<List<GoalEntity>> getGoals() async {
    final models = await isar.goalModels.where().findAll();
    return models.map(GoalMapper.toEntity).toList();
  }

  @override
  Future<bool> saveGoal(GoalEntity goal) async {
    try {
      await isar.writeTxn(() async {
        await isar.goalModels.put(
          GoalMapper.toModel(goal),
        );
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteGoal(String id) async {
    try {
      final goalId = int.parse(id);

      await isar.writeTxn(() async {
        await isar.goalModels.delete(goalId);
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}