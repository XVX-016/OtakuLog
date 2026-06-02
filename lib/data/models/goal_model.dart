import 'package:isar/isar.dart';

part 'goal_model.g.dart';

@collection
class GoalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String goalType;

  late int targetValue;

  late int month;

  late int year;
}