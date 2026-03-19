import 'package:dio/dio.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class MangadexService {
  final Dio _dio;
  final Map<String, int> _chapterCountCache = {};

  static const List<String> _adultTagIds = [
    '97893a4c-12af-4dac-b6be-0dffb353568e',
    'b29d6a3d-1569-4e7a-8caf-7557bc92cd5d',
    'aafb99c1-7f60-43fa-b75f-fc9502ce29c7',
  ];
  static const Map<String, String> _tagIdsByName = {
    'Ecchi': '97893a4c-12af-4dac-b6be-0dffb353568e',
    'Harem': 'b29d6a3d-1569-4e7a-8caf-7557bc92cd5d',
    'Hentai': 'aafb99c1-7f60-43fa-b75f-fc9502ce29c7',
  };

  MangadexService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.mangadex.org'));

  Future<List<SearchResultItem>> searchManga(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    if (query.trim().isEmpty) {
      return fetchTrendingManga(page: page, perPage: perPage, filters: filters);
    }

    final params = _baseParams(page, perPage, filters)
      ..['title'] = query.trim();

    return _fetchResults(params, filters);
  }

  Future<List<SearchResultItem>> fetchTrendingManga({
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    final params = _baseParams(page, perPage, filters)
      ..addAll(_sortParams(filters.sort));

    return _fetchResults(params, filters);
  }

  Map<String, dynamic> _baseParams(int page, int perPage, SearchFilters filters) {
    final params = <String, dynamic>{
      'limit': perPage,
      'offset': (page - 1) * perPage,
      'includes[]': ['cover_art', 'author', 'artist'],
      'availableTranslatedLanguage[]': ['en'],
    };

    _applyAdultMode(params, filters.adultMode);

    final status = _mapMangaStatus(filters.status);
    if (status != null) {
      params['status[]'] = [status];
    }

    final includedTags = filters.includedTags
        .map((tag) => _tagIdsByName[tag])
        .whereType<String>()
        .toList();
    final excludedTags = filters.excludedTags
        .map((tag) => _tagIdsByName[tag])
        .whereType<String>()
        .toList();
    if (includedTags.isNotEmpty) {
      params['includedTags[]'] = [
        ...(params['includedTags[]'] as List? ?? const []),
        ...includedTags,
      ];
      params['includedTagsMode'] = 'OR';
    }
    if (excludedTags.isNotEmpty) {
      params['excludedTags[]'] = [
        ...(params['excludedTags[]'] as List? ?? const []),
        ...excludedTags,
      ];
      params['excludedTagsMode'] = 'OR';
    }

    return params;
  }

  Future<List<SearchResultItem>> _fetchResults(
    Map<String, dynamic> params,
    SearchFilters filters,
  ) async {
    final response = await _requestManga(params);
    final List data = response.data['data'] ?? [];
    final mapped = data.map((item) => _mapToResult(item as Map<String, dynamic>)).toList();
    final filtered = _applyLocalTagFiltering(mapped, filters);
    if (filtered.isNotEmpty || params['title'] == null) {
      return filtered;
    }

    final fallbackParams = Map<String, dynamic>.from(params)
      ..remove('availableTranslatedLanguage[]');
    final fallbackResponse = await _requestManga(fallbackParams);
    final List fallbackData = fallbackResponse.data['data'] ?? [];
    final fallbackMapped = fallbackData
        .map((item) => _mapToResult(item as Map<String, dynamic>))
        .toList();
    final fallbackFiltered = _applyLocalTagFiltering(fallbackMapped, filters);
    if (fallbackFiltered.isNotEmpty) {
      return fallbackFiltered;
    }

    final broadParams = _broadSearchParams(params, filters);
    final broadResponse = await _requestManga(broadParams);
    final List broadData = broadResponse.data['data'] ?? [];
    final broadMapped = broadData
        .map((item) => _mapToResult(item as Map<String, dynamic>))
        .toList();
    return _applyLocalTagFiltering(broadMapped, filters);
  }

  Future<Response<dynamic>> _requestManga(Map<String, dynamic> queryParams) async {
    try {
      return await _dio.get('/manga', queryParameters: queryParams);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final hasTagFilters = queryParams.containsKey('includedTags[]') || queryParams.containsKey('excludedTags[]');
      if (statusCode != 400 || !hasTagFilters) rethrow;

      final fallbackParams = Map<String, dynamic>.from(queryParams)
        ..remove('includedTags[]')
        ..remove('includedTagsMode')
        ..remove('excludedTags[]')
        ..remove('excludedTagsMode');

      return await _dio.get('/manga', queryParameters: fallbackParams);
    }
  }

  void _applyAdultMode(Map<String, dynamic> params, AdultMode adultMode) {
    switch (adultMode) {
      case AdultMode.off:
        params['contentRating[]'] = ['safe', 'suggestive'];
        params['excludedTags[]'] = _adultTagIds;
        params['excludedTagsMode'] = 'OR';
        break;
      case AdultMode.mixed:
        params['contentRating[]'] = ['safe', 'suggestive', 'erotica', 'pornographic'];
        break;
      case AdultMode.explicitOnly:
        params['contentRating[]'] = ['erotica', 'pornographic'];
        params['includedTags[]'] = _adultTagIds;
        params['includedTagsMode'] = 'OR';
        break;
    }
  }

  Map<String, dynamic> _sortParams(SearchSort sort) {
    switch (sort) {
      case SearchSort.trending:
        return {'order[followedCount]': 'desc'};
      case SearchSort.popular:
        return {'order[rating]': 'desc'};
      case SearchSort.updated:
        return {'order[updatedAt]': 'desc'};
      case SearchSort.score:
        return {'order[rating]': 'desc'};
    }
  }

  String? _mapMangaStatus(ContentStatusFilter status) {
    switch (status) {
      case ContentStatusFilter.ongoing:
      case ContentStatusFilter.airing:
        return 'ongoing';
      case ContentStatusFilter.completed:
      case ContentStatusFilter.finished:
        return 'completed';
      case ContentStatusFilter.any:
        return null;
    }
  }

  List<SearchResultItem> _applyLocalTagFiltering(
    List<SearchResultItem> items,
    SearchFilters filters,
  ) {
    if (filters.includedTags.isEmpty && filters.excludedTags.isEmpty) return items;

    return items.where((item) {
      final lowerTags = item.tags.map((tag) => tag.toLowerCase()).toSet();
      final included = filters.includedTags.isEmpty ||
          filters.includedTags.any(
            (tag) => lowerTags.contains(tag.toLowerCase()),
          );
      final excluded = filters.excludedTags.any((tag) => lowerTags.contains(tag.toLowerCase()));
      return included && !excluded;
    }).toList();
  }

  Map<String, dynamic> _broadSearchParams(
    Map<String, dynamic> params,
    SearchFilters filters,
  ) {
    final broad = <String, dynamic>{
      'limit': params['limit'],
      'offset': params['offset'],
      'includes[]': ['cover_art', 'author', 'artist'],
      if (params['title'] != null) 'title': params['title'],
    };
    _applyAdultMode(broad, filters.adultMode);
    return broad;
  }

  SearchResultItem _mapToResult(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map? ?? const {};
    final id = (json['id'] ?? '').toString();
    final relationships = json['relationships'] as List? ?? const [];

    final titleMap = attributes['title'] as Map? ?? const {};
    final resolvedTitle = (titleMap['en'] ?? (titleMap.values.isNotEmpty ? titleMap.values.first : 'Unknown')).toString();
    final coverFile = _relationshipFileName(relationships);
    final coverUrl = coverFile.isNotEmpty ? 'https://uploads.mangadex.org/covers/$id/$coverFile.256.jpg' : '';
    final tags = (attributes['tags'] as List? ?? const [])
        .map((tag) => ((((tag as Map?)?['attributes'] as Map?)?['name'] as Map?)?['en'] ?? '').toString())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final descriptionMap = attributes['description'] as Map? ?? const {};
    final description = stripHtmlTags(
      (descriptionMap['en'] ??
              (descriptionMap.values.isNotEmpty
                  ? descriptionMap.values.first
                  : null))
          ?.toString(),
    );
    final creators = _creatorNames(relationships);
    final totalChapters = _parseLastChapter(attributes['lastChapter']);
    final contentRating = (attributes['contentRating'] ?? 'safe').toString();
    final originalLanguage = (attributes['originalLanguage'] ?? '').toString();

    final content = MangaEntity(
      id: id,
      title: resolvedTitle,
      coverImage: coverUrl,
      totalChapters: totalChapters,
      currentChapter: 0,
      status: MangaStatus.reading,
      genres: tags,
      description: description,
      isAdult: contentRating == 'erotica' || contentRating == 'pornographic',
      createdAt: _parseDate(attributes['createdAt']),
      updatedAt: _parseDate(attributes['updatedAt']),
    );

    return SearchResultItem(
      id: id,
      content: content,
      medium: SearchMedium.manga,
      tags: tags,
      description: description,
      score: null,
      isAdult: content.isAdult,
      statusLabel: attributes['status']?.toString(),
      sourceLabel: 'MangaDex',
      mangaCategory: _mapMangaCategory(originalLanguage),
      creatorNames: creators,
      totalCount: totalChapters > 0 ? totalChapters : null,
    );
  }

  MangaCategoryFilter _mapMangaCategory(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ko':
        return MangaCategoryFilter.manhwa;
      case 'zh':
      case 'zh-hk':
      case 'zh-ro':
      case 'zh-tw':
        return MangaCategoryFilter.manhua;
      case 'ja':
      default:
        return MangaCategoryFilter.manga;
    }
  }

  String _relationshipFileName(List relationships) {
    final coverRel = relationships.cast<Map?>().firstWhere(
          (relationship) => relationship?['type'] == 'cover_art',
          orElse: () => null,
        );
    return ((coverRel?['attributes'] as Map?)?['fileName'] ?? '').toString();
  }

  List<String> _creatorNames(List relationships) {
    return relationships
        .cast<Map?>()
        .where((relationship) => relationship?['type'] == 'author' || relationship?['type'] == 'artist')
        .map((relationship) => ((relationship?['attributes'] as Map?)?['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  int _parseLastChapter(dynamic lastChapter) {
    if (lastChapter is int) return lastChapter;
    if (lastChapter is String) return int.tryParse(lastChapter) ?? 0;
    return 0;
  }

  DateTime _parseDate(dynamic raw) {
    final fallback = DateTime.now();
    if (raw is! String || raw.isEmpty) return fallback;
    return DateTime.tryParse(raw) ?? fallback;
  }

  Future<int> fetchChapterCount(String mangaId) async {
    if (_chapterCountCache.containsKey(mangaId)) {
      return _chapterCountCache[mangaId]!;
    }

    try {
      final response = await _dio.get(
        '/manga/$mangaId/feed',
        queryParameters: {'limit': 1, 'offset': 0},
      );
      final total = response.data['total'] ?? 0;
      _chapterCountCache[mangaId] = total;
      return total;
    } catch (_) {
      return 0;
    }
  }
}
