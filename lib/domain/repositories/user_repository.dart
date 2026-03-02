import 'package:goon_tracker/domain/entities/user.dart';

abstract class UserRepository {
  Future<UserEntity?> getUser();
  Future<bool> saveUser(UserEntity user);
}
