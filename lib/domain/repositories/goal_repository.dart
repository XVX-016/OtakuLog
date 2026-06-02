import 'package:otakulog/domain/entities/goal.dart';

abstract class GoalRepository {
  Future<List<GoalEntity>> getGoals();
  Future<bool> saveGoal(GoalEntity goal);
  Future<bool> deleteGoal(String id);
}