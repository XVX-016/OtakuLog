import 'package:otakulog/data/models/user_model.dart';
import 'package:otakulog/domain/entities/user.dart';

class UserMapper {
  static UserEntity toEntity(UserModel model) {
    return UserEntity(
      id: model.localId,
      name: model.name,
      avatarPath: model.avatarPath,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      defaultSearchType: model.defaultSearchType,
      defaultContentRating: model.defaultContentRating,
      defaultAnimeWatchTime: model.defaultAnimeWatchTime,
      defaultMangaReadTime: model.defaultMangaReadTime,
      filter18Plus: model.filter18Plus,
    );
  }

  static UserModel toModel(UserEntity entity) {
    return UserModel()
      ..localId = entity.id
      ..name = entity.name
      ..avatarPath = entity.avatarPath
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..defaultSearchType = entity.defaultSearchType
      ..defaultContentRating = entity.defaultContentRating
      ..defaultAnimeWatchTime = entity.defaultAnimeWatchTime
      ..defaultMangaReadTime = entity.defaultMangaReadTime
      ..filter18Plus = entity.filter18Plus;
  }
}
