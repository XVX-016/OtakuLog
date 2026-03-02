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
    final result = await isar.dailyActivitys.filter().dateGreaterThan(startAt).findAll();
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> logActivity(DateTime date, {int? minutesWatched, int? minutesRead}) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    await isar.writeTxn(() async {
      var activityModel = await isar.dailyActivitys.filter().dateEqualTo(normalizedDate).findFirst();
      if (activityModel == null) {
        activityModel = DailyActivity()
          ..date = normalizedDate
          ..minutesWatched = minutesWatched ?? 0
          ..minutesRead = minutesRead ?? 0;
      } else {
        if (minutesWatched != null) activityModel.minutesWatched += minutesWatched;
        if (minutesRead != null) activityModel.minutesRead += minutesRead;
      }
      await isar.dailyActivitys.put(activityModel);
    });
  }

  @override
  Future<Activity?> getActivityByDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final result = await isar.dailyActivitys.filter().dateEqualTo(normalizedDate).findFirst();
    return result?.toEntity();
  }
}
