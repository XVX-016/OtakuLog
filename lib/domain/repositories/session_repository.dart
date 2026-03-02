import 'package:goon_tracker/domain/entities/user_session.dart';

abstract class SessionRepository {
  Future<List<UserSessionEntity>> getAllSessions();
  Future<List<UserSessionEntity>> getSessionsInRange(DateTime start, DateTime end);
  Future<void> saveSession(UserSessionEntity session);
  Future<void> deleteSession(String id);
}
