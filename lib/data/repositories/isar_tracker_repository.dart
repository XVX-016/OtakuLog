import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/daily_activity.dart';
import 'package:goon_tracker/domain/entities/activity.dart';
import 'package:goon_tracker/domain/repositories/tracker_repository.dart';

class IsarTrackerRepository implements TrackerRepository {
  final Isar isar;

  IsarTrackerRepository(this.isar);

  @override
  Future<List<Activity>> getRecentActivity(int days) async {
    final startAt = DateTime.now().subtract(Duration(days: days));
    final result =
        await isar.dailyActivitys.filter().dateGreaterThan(startAt).findAll();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Activity>> getActivityByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = month == 12
        ? DateTime(year + 1, 1, 1).subtract(const Duration(milliseconds: 1))
        : DateTime(year, month + 1, 1)
            .subtract(const Duration(milliseconds: 1));
    final result = await isar.dailyActivitys
        .filter()
        .dateGreaterThan(start.subtract(const Duration(milliseconds: 1)))
        .and()
        .dateLessThan(end.add(const Duration(milliseconds: 1)))
        .findAll();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<DateTime?> getEarliestActivityDate() async {
    final earliest = await isar.dailyActivitys.where().sortByDate().findFirst();
    return earliest?.date;
  }

  @override
  Future<void> logActivity(DateTime date,
      {int? minutesWatched, int? minutesRead}) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    await isar.writeTxn(() async {
      var activityModel = await isar.dailyActivitys
          .filter()
          .dateEqualTo(normalizedDate)
          .findFirst();
      if (activityModel == null) {
        activityModel = DailyActivity()
          ..date = normalizedDate
          ..minutesWatched = (minutesWatched ?? 0).clamp(0, 1 << 31)
          ..minutesRead = (minutesRead ?? 0).clamp(0, 1 << 31);
      } else {
        if (minutesWatched != null) {
          activityModel.minutesWatched =
              (activityModel.minutesWatched + minutesWatched).clamp(0, 1 << 31);
        }
        if (minutesRead != null) {
          activityModel.minutesRead =
              (activityModel.minutesRead + minutesRead).clamp(0, 1 << 31);
        }
      }
      await isar.dailyActivitys.put(activityModel);
    });
  }

  @override
  Future<Activity?> getActivityByDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final result = await isar.dailyActivitys
        .filter()
        .dateEqualTo(normalizedDate)
        .findFirst();
    return result?.toEntity();
  }
}
