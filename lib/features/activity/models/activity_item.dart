import 'package:goon_tracker/domain/entities/user_session.dart';

enum ActivityItemType { anime, manga }

class ActivityItem {
  final ActivityItemType type;
  final String title;
  final int delta;
  final DateTime timestamp;
  final int minutesAdded;
  final String contentId;

  const ActivityItem({
    required this.type,
    required this.title,
    required this.delta,
    required this.timestamp,
    required this.minutesAdded,
    required this.contentId,
  });

  String get actionLabel {
    if (type == ActivityItemType.anime) {
      return 'Watched $delta ${delta == 1 ? 'episode' : 'episodes'} of $title';
    }
    return 'Read $delta ${delta == 1 ? 'chapter' : 'chapters'} of $title';
  }

  static ActivityItem fromSession(
    UserSessionEntity session, {
    required String title,
  }) {
    return ActivityItem(
      type: session.contentType == SessionContentType.anime ? ActivityItemType.anime : ActivityItemType.manga,
      title: title,
      delta: session.unitsConsumed,
      timestamp: session.endTime,
      minutesAdded: session.totalMinutes,
      contentId: session.contentId,
    );
  }
}
