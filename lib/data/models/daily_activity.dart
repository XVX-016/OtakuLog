import 'package:isar/isar.dart';
import 'package:goon_tracker/domain/entities/activity.dart';

part 'daily_activity.g.dart';

@collection
class DailyActivity {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late int minutesWatched;
  late int minutesRead;

  Activity toEntity() => Activity(
        id: id,
        date: date,
        minutesWatched: minutesWatched,
        minutesRead: minutesRead,
      );

  static DailyActivity fromEntity(Activity entity) => DailyActivity()
    ..id = entity.id
    ..date = entity.date
    ..minutesWatched = entity.minutesWatched
    ..minutesRead = entity.minutesRead;
}
