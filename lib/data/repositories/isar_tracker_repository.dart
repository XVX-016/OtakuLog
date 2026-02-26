import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/daily_activity.dart';
import 'package:goon_tracker/domain/repositories/tracker_repository.dart';

class IsarTrackerRepository implements TrackerRepository {
  final Isar isar;

  IsarTrackerRepository(this.isar);

  @override
  Future<List<DailyActivity>> getRecentActivity(int days) {
    final startAt = DateTime.now().subtract(Duration(days: days));
    return isar.dailyActivitys.filter().dateGreaterThan(startAt).findAll();
  }

  @override
  Future<void> logActivity(DateTime date, {int? minutesWatched, int? minutesRead}) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    await isar.writeTxn(() async {
      var activity = await isar.dailyActivitys.filter().dateEqualTo(normalizedDate).findFirst();
      if (activity == null) {
        activity = DailyActivity()
          ..date = normalizedDate
          ..minutesWatched = minutesWatched ?? 0
          ..minutesRead = minutesRead ?? 0;
      } else {
        if (minutesWatched != null) activity.minutesWatched += minutesWatched;
        if (minutesRead != null) activity.minutesRead += minutesRead;
      }
      await isar.dailyActivitys.put(activity);
    });
  }

  @override
  Future<DailyActivity?> getActivityByDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return isar.dailyActivitys.filter().dateEqualTo(normalizedDate).findFirst();
  }
}
