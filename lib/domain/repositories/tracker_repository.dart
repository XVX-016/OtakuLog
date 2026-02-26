import 'package:goon_tracker/domain/entities/activity.dart';

abstract class TrackerRepository {
  Future<List<Activity>> getRecentActivity(int days);
  Future<void> logActivity(DateTime date, {int? minutesWatched, int? minutesRead});
  Future<Activity?> getActivityByDate(DateTime date);
}
