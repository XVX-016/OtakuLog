import 'package:isar/isar.dart';
import 'package:goon_tracker/data/mappers/user_session_mapper.dart';
import 'package:goon_tracker/data/models/user_session_model.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  final Isar isar;

  SessionRepositoryImpl(this.isar);

  @override
  Future<List<UserSessionEntity>> getAllSessions() async {
    final models = await isar.userSessionModels.where().findAll();
    return models.map(UserSessionMapper.toEntity).toList();
  }

  @override
  Future<List<UserSessionEntity>> getSessionsInRange(DateTime start, DateTime end) async {
    final models = await isar.userSessionModels
        .filter()
        .startTimeGreaterThan(start)
        .and()
        .startTimeLessThan(end)
        .findAll();
    return models.map(UserSessionMapper.toEntity).toList();
  }

  @override
  Future<void> saveSession(UserSessionEntity session) async {
    await isar.writeTxn(() async {
      await isar.userSessionModels.put(UserSessionMapper.toModel(session));
    });
  }

  @override
  Future<void> deleteSession(String id) async {
    final isarId = int.tryParse(id);
    if (isarId != null) {
      await isar.writeTxn(() async {
        await isar.userSessionModels.delete(isarId);
      });
    }
  }
}
