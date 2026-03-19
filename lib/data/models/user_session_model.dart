import 'package:isar/isar.dart';

part 'user_session_model.g.dart';

@collection
class UserSessionModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? localId;

  @Index()
  late String contentId;
  
  @enumerated
  late SessionContentTypeModel contentType;
  
  late DateTime startTime;
  late DateTime endTime;
  late int unitsConsumed;
}

enum SessionContentTypeModel { anime, manga }
