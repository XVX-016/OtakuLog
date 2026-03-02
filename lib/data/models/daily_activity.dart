import 'package:isar/isar.dart';
import 'package:goon_tracker/domain/entities/activity.dart';

part 'daily_activity.g.dart';

@collection
class DailyActivity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  late int minutesWatched;
  
  late int minutesRead;

  Activity toEntity() {
    return Activity(
      id: id,
      date: date,
      minutesWatched: minutesWatched,
      minutesRead: minutesRead,
    );
  }
}
