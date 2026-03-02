import 'trackable_content.dart';

enum MangaStatus { reading, completed, dropped, onHold }

class MangaEntity implements TrackableContent {
  @override
  final String id;
  @override
  final String title;
  @override
  final String coverImage;
  
  final int totalChapters;
  final int currentChapter;
  final MangaStatus status;
  @override
  final double? rating;
  final bool isAdult;
  
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  int get currentProgress => currentChapter;
  @override
  int get totalProgress => totalChapters;

  MangaEntity({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.totalChapters,
    required this.currentChapter,
    required this.status,
    this.rating,
    required this.isAdult,
    required this.createdAt,
    required this.updatedAt,
  });

  MangaEntity copyWith({
    String? title,
    String? coverImage,
    int? totalChapters,
    int? currentChapter,
    MangaStatus? status,
    double? rating,
    bool? isAdult,
    DateTime? updatedAt,
  }) {
    return MangaEntity(
      id: id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      totalChapters: totalChapters ?? this.totalChapters,
      currentChapter: currentChapter ?? this.currentChapter,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      isAdult: isAdult ?? this.isAdult,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
