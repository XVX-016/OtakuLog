import 'package:goon_tracker/domain/entities/user_session.dart';

abstract class SessionRepository {
  Future<List<UserSessionEntity>> getAllSessions();
  Future<List<UserSessionEntity>> getRecentSessions();
  Future<List<UserSessionEntity>> getSessionsInRange(DateTime start, DateTime end);
  Future<bool> saveSession(UserSessionEntity session);
  Future<bool> deleteSession(String id);
}
