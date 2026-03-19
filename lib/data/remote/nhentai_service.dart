import 'package:dio/dio.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';

class NhentaiService {
  final Dio _dio;

  NhentaiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://nhentai.net/api',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  Future<List<SearchResultItem>> searchManga(
    String query, {
    required int page,
    required SearchFilters filters,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final response = await _dio.get(
      '/galleries/search',
      queryParameters: {
        'query': trimmedQuery,
        'page': page,
      },
    );

    final galleries = (response.data['result'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    final mapped = galleries.map(_mapToResult).toList();
    return _applyLocalTagFiltering(mapped, filters);
  }

  List<SearchResultItem> _applyLocalTagFiltering(
    List<SearchResultItem> items,
    SearchFilters filters,
  ) {
    if (filters.includedTags.isEmpty && filters.excludedTags.isEmpty) {
      return items;
    }

    return items.where((item) {
      final lowerTags = item.tags.map((tag) => tag.toLowerCase()).toSet();
      final included = filters.includedTags.every(
        (tag) => lowerTags.contains(tag.toLowerCase()),
      );
      final excluded = filters.excludedTags.any(
        (tag) => lowerTags.contains(tag.toLowerCase()),
      );
      return included && !excluded;
    }).toList();
  }

  SearchResultItem _mapToResult(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? '').toString();
    final mediaId = (json['media_id'] ?? '').toString();
    final titleMap = (json['title'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawTags =
        (json['tags'] as List? ?? const []).whereType<Map<String, dynamic>>();
    final uploadDateSeconds = (json['upload_date'] as num?)?.toInt();
    final uploadDate = uploadDateSeconds == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(uploadDateSeconds * 1000);

    final searchTags = rawTags
        .where((tag) => !_isMetaTagType((tag['type'] ?? '').toString()))
        .map((tag) => (tag['name'] ?? '').toString())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final creatorNames = rawTags
        .where((tag) {
          final type = (tag['type'] ?? '').toString();
          return type == 'artist' || type == 'group';
        })
        .map((tag) => (tag['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final coverType = (((json['images'] as Map?)?['cover'] as Map?)?['t'] ?? 'j')
        .toString();
    final coverUrl = mediaId.isEmpty
        ? ''
        : 'https://t.nhentai.net/galleries/$mediaId/cover.${_fileExtension(coverType)}';
    final title = _resolveTitle(titleMap);

    final content = MangaEntity(
      id: 'nhentai:$rawId',
      title: title,
      coverImage: coverUrl,
      totalChapters: 0,
      currentChapter: 0,
      status: MangaStatus.reading,
      genres: searchTags.take(12).toList(),
      description: null,
      isAdult: true,
      createdAt: uploadDate,
      updatedAt: uploadDate,
    );

    return SearchResultItem(
      id: content.id,
      content: content,
      medium: SearchMedium.manga,
      tags: searchTags.take(6).toList(),
      description: null,
      isAdult: true,
      statusLabel: 'NHENTAI',
      creatorNames: creatorNames,
      totalCount: null,
    );
  }

  bool _isMetaTagType(String type) {
    return type == 'artist' ||
        type == 'group' ||
        type == 'language' ||
        type == 'category' ||
        type == 'parody' ||
        type == 'character';
  }

  String _resolveTitle(Map<String, dynamic> titleMap) {
    return (titleMap['english'] ??
            titleMap['pretty'] ??
            titleMap['japanese'] ??
            'Unknown title')
        .toString();
  }

  String _fileExtension(String imageType) {
    switch (imageType) {
      case 'p':
        return 'png';
      case 'g':
        return 'gif';
      case 'j':
      default:
        return 'jpg';
    }
  }
}
