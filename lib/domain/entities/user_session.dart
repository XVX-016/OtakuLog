enum SessionContentType { anime, manga }

class UserSessionEntity {
  final String id;
  final String contentId;
  final SessionContentType contentType;
  final DateTime startTime;
  final DateTime endTime;
  final int unitsConsumed;

  UserSessionEntity({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.startTime,
    required this.endTime,
    required this.unitsConsumed,
  });

  int get totalMinutes => endTime.difference(startTime).inMinutes;
}
