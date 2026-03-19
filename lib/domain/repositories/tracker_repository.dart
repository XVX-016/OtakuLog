import 'package:goon_tracker/domain/entities/activity.dart';

abstract class TrackerRepository {
  Future<List<Activity>> getRecentActivity(int days);
  Future<List<Activity>> getActivityByMonth(int year, int month);
  Future<DateTime?> getEarliestActivityDate();
  Future<void> logActivity(DateTime date, {int? minutesWatched, int? minutesRead});
  Future<Activity?> getActivityByDate(DateTime date);
}
