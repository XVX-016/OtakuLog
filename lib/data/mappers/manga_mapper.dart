import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/search/models/search_filters.dart';

class MangaMapper {
  static MangaEntity fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};
    final id = json['id'] ?? '';
    final relationships = json['relationships'] as List? ?? [];

    // Title parsing with fallbacks
    final titleMap = attributes['title'] as Map? ?? {};
    final title = titleMap['en'] ??
        (titleMap.values.isNotEmpty ? titleMap.values.first : 'Unknown Title');

    // Cover parsing with defensive checks
    String coverFileName = '';
    final coverRel = relationships.firstWhere(
      (r) => r['type'] == 'cover_art',
      orElse: () => null,
    );
    if (coverRel != null && coverRel['attributes'] != null) {
      coverFileName = coverRel['attributes']['fileName'] ?? '';
    }

    final coverUrl = coverFileName.isNotEmpty
        ? 'https://uploads.mangadex.org/covers/$id/$coverFileName.256.jpg'
        : '';

    // Tags/Genres parsing
    final genres = (attributes['tags'] as List? ?? [])
        .map((tag) {
          final tagAttr = tag['attributes'] ?? {};
          final tagNameMap = tagAttr['name'] as Map? ?? {};
          return (tagNameMap['en'] ?? '') as String;
        })
        .where((name) => name.isNotEmpty)
        .toList();

    // Description parsing
    final descMap = attributes['description'] as Map? ?? {};
    final description = descMap['en'] ??
        (descMap.values.isNotEmpty ? descMap.values.first : null);

    // Metadata
    final contentRating = attributes['contentRating'] ?? 'safe';
    final createdAtStr =
        attributes['createdAt'] ?? DateTime.now().toIso8601String();
    final updatedAtStr = attributes['updatedAt'] ?? createdAtStr;

    return MangaEntity(
      id: id,
      title: title,
      coverImage: coverUrl,
      totalChapters: _parseLastChapter(attributes['lastChapter']),
      currentChapter: 0,
      status: MangaStatus.reading,
      mangaCategory: _mapOriginalLanguageToCategory(
        attributes['originalLanguage'] as String?,
      ),
      rating: null,
      genres: genres,
      description: description,
      isAdult: contentRating == 'erotica' || contentRating == 'pornographic',
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  static MangaCategoryFilter _mapOriginalLanguageToCategory(String? language) {
    switch (language) {
      case 'ko':
        return MangaCategoryFilter.manhwa;
      case 'zh':
      case 'zh-hk':
      case 'zh-ro':
      case 'zh-tw':
        return MangaCategoryFilter.manhua;
      default:
        return MangaCategoryFilter.manga;
    }
  }

  static int _parseLastChapter(dynamic lastChapter) {
    if (lastChapter == null) return 0;
    if (lastChapter is int) return lastChapter;
    if (lastChapter is String) return int.tryParse(lastChapter) ?? 0;
    return 0;
  }

  static MangaEntity toEntity(MangaModel model) {
    return MangaEntity(
      id: model.remoteId,
      title: model.title,
      coverImage: model.coverImage,
      totalChapters: model.totalChapters,
      currentChapter: model.currentChapter,
      status: _mapStatusFromModel(model.status),
      rating: model.rating,
      genres: model.genres,
      description: model.description,
      isAdult: model.isAdult,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      mangaCategory: model.mangaCategory,
      watchOrder: model.watchOrder,
    );
  }

  static MangaModel toModel(MangaEntity entity) {
    return MangaModel()
      ..remoteId = entity.id
      ..title = entity.title
      ..coverImage = entity.coverImage
      ..totalChapters = entity.totalChapters
      ..currentChapter = entity.currentChapter
      ..status = _mapStatusToModel(entity.status)
      ..mangaCategory = entity.mangaCategory
      ..rating = entity.rating
      ..genres = entity.genres
      ..description = entity.description
      ..isAdult = entity.isAdult
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..watchOrder = entity.watchOrder;
  }

  static MangaStatus _mapStatusFromModel(MangaStatusModel model) {
    switch (model) {
      case MangaStatusModel.reading:
        return MangaStatus.reading;
      case MangaStatusModel.completed:
        return MangaStatus.completed;
      case MangaStatusModel.dropped:
        return MangaStatus.dropped;
      case MangaStatusModel.onHold:
        return MangaStatus.onHold;
    }
  }

  static MangaStatusModel _mapStatusToModel(MangaStatus status) {
    switch (status) {
      case MangaStatus.reading:
        return MangaStatusModel.reading;
      case MangaStatus.completed:
        return MangaStatusModel.completed;
      case MangaStatus.dropped:
        return MangaStatusModel.dropped;
      case MangaStatus.onHold:
        return MangaStatusModel.onHold;
    }
  }
}
