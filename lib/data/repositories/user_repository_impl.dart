import 'package:isar/isar.dart';
import 'package:otakulog/data/models/user_model.dart';
import 'package:otakulog/data/mappers/user_mapper.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final Isar _isar;

  UserRepositoryImpl(this._isar);

  @override
  Future<UserEntity?> getUser(String id) async {
    final model = await _isar.userModels.filter().localIdEqualTo(id).findFirst();
    if (model == null) return null;
    return UserMapper.toEntity(model);
  }

  @override
  Future<bool> saveUser(UserEntity user) async {
    final model = UserMapper.toModel(user);

    final existing = await _isar.userModels.filter().localIdEqualTo(user.id).findFirst();
    if (existing != null) {
      model.id = existing.id;
    }

    try {
      await _isar.writeTxn(() async {
        await _isar.userModels.put(model);
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
