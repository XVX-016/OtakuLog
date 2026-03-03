import 'package:isar/isar.dart';
import 'package:goon_tracker/data/models/user_model.dart';
import 'package:goon_tracker/data/mappers/user_mapper.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/repositories/user_repository.dart';

extension on QueryBuilder<UserModel, UserModel, QFilterCondition> {
  QueryBuilder<UserModel, UserModel, QAfterFilterCondition> localIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }
}

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
