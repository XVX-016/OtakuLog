import 'package:isar/isar.dart';
import 'package:goon_tracker/data/local/isar_service.dart';
import 'package:goon_tracker/data/models/user_model.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final Isar _isar;

  UserRepositoryImpl(this._isar);

  @override
  Future<UserEntity?> getUser() async {
    final model = await _isar.userModels.where().findFirst();
    if (model == null) return null;
    return UserEntity(
      id: model.id.toString(),
      name: model.name,
      avatarPath: model.avatarPath,
      defaultMangaReadTime: model.defaultMangaReadTime,
      defaultAnimeWatchTime: model.defaultAnimeWatchTime,
      defaultSearchType: model.defaultSearchType,
      defaultContentRating: model.defaultContentRating,
      filter18Plus: model.filter18Plus,
    );
  }

  @override
  Future<bool> saveUser(UserEntity user) async {
    final model = UserModel()
      ..name = user.name
      ..avatarPath = user.avatarPath
      ..defaultMangaReadTime = user.defaultMangaReadTime
      ..defaultAnimeWatchTime = user.defaultAnimeWatchTime
      ..defaultSearchType = user.defaultSearchType
      ..defaultContentRating = user.defaultContentRating
      ..filter18Plus = user.filter18Plus;
    
    if (user.id != null) {
      model.id = int.tryParse(user.id!) ?? Isar.autoIncrement;
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
