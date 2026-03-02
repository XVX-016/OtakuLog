abstract class TrackableContent {
  String get id;
  String get title;
  String get coverImage;
  double? get rating;
  int get currentProgress;
  int get totalProgress;
  DateTime get updatedAt;
}
