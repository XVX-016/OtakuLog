import 'package:goon_tracker/data/models/user_session_model.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';

class UserSessionMapper {
  static UserSessionEntity toEntity(UserSessionModel model) {
    return UserSessionEntity(
      id: model.localId?.isNotEmpty == true ? model.localId! : model.id.toString(),
      contentId: model.contentId,
      contentType: _mapContentTypeToEntity(model.contentType),
      startTime: model.startTime,
      endTime: model.endTime,
      unitsConsumed: model.unitsConsumed,
    );
  }

  static UserSessionModel toModel(UserSessionEntity entity) {
    return UserSessionModel()
      ..localId = entity.id
      ..contentId = entity.contentId
      ..contentType = _mapContentTypeToModel(entity.contentType)
      ..startTime = entity.startTime
      ..endTime = entity.endTime
      ..unitsConsumed = entity.unitsConsumed;
  }

  static SessionContentType _mapContentTypeToEntity(SessionContentTypeModel modelType) {
    switch (modelType) {
      case SessionContentTypeModel.anime:
        return SessionContentType.anime;
      case SessionContentTypeModel.manga:
        return SessionContentType.manga;
    }
  }

  static SessionContentTypeModel _mapContentTypeToModel(SessionContentType entityType) {
    switch (entityType) {
      case SessionContentType.anime:
        return SessionContentTypeModel.anime;
      case SessionContentType.manga:
        return SessionContentTypeModel.manga;
    }
  }
}
