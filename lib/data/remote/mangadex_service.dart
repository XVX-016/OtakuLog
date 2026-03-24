import 'package:dio/dio.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class MangadexService {
  final Dio _dio;
  final Map<String, int> _chapterCountCache = {};
  final Map<String, double?> _latestChapterCache = {};
  final Map<String, String?> _titleResolutionCache = {};
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _coverIdPattern = RegExp(
    r'uploads\.mangadex\.org/covers/([0-9a-fA-F-]{36})/',
    caseSensitive: false,
  );

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

  String? resolveMangaDexMangaId(
    String mangaId, {
    String? coverImageUrl,
  }) {
    final normalizedId = mangaId.trim();
    if (_uuidPattern.hasMatch(normalizedId)) {
      return normalizedId;
    }

    final coverMatch = _coverIdPattern.firstMatch(coverImageUrl ?? '');
    final coverId = coverMatch?.group(1);
    if (coverId != null && _uuidPattern.hasMatch(coverId)) {
      return coverId;
    }

    return null;
  }

  bool supportsReaderForMangaId(
    String mangaId, {
    String? coverImageUrl,
  }) {
    return resolveMangaDexMangaId(
          mangaId,
          coverImageUrl: coverImageUrl,
        ) !=
        null;
  }

  Future<String?> resolveMangaDexMangaIdForTitle(String title) async {
    final normalizedTitle = _normalizeTitle(title);
    if (normalizedTitle.isEmpty) return null;
    if (_titleResolutionCache.containsKey(normalizedTitle)) {
      return _titleResolutionCache[normalizedTitle];
    }

    try {
      String? resolved;
      for (final variant in _titleVariants(title)) {
        resolved = await _resolveByRawTitleSearch(variant, normalizedTitle);
        if (resolved != null) break;
      }
      _titleResolutionCache[normalizedTitle] = resolved;
      return resolved;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> debugReaderCandidatesForTitle(String title) async {
    final output = <String>[];
    final seen = <String>{};

    try {
      for (final variant in _titleVariants(title)) {
        if (!seen.add(variant)) continue;
        final response = await _dio.get(
          '/manga',
          queryParameters: {
            'title': variant.trim(),
            'limit': 3,
            'includes[]': ['cover_art'],
          },
        );

        final List data = response.data['data'] ?? const [];
        if (data.isEmpty) {
          output.add('$variant -> no results');
          continue;
        }

        for (final raw in data.cast<Map<String, dynamic>>()) {
          final id = raw['id']?.toString() ?? 'unknown-id';
          final attributes = raw['attributes'] as Map? ?? const {};
          final titleMap = attributes['title'] as Map? ?? const {};
          final resultTitle = (titleMap['en'] ??
                  (titleMap.values.isNotEmpty ? titleMap.values.first : 'Unknown'))
              .toString();
          output.add('$variant -> $resultTitle [$id]');
        }
      }
    } catch (error) {
      output.add('debug lookup failed: $error');
    }

    return output;
  }

  Iterable<String> _titleVariants(String rawTitle) sync* {
    final full = rawTitle.trim();
    if (full.isEmpty) return;
    yield full;

    final colon = rawTitle.split(':').first.trim();
    if (colon.isNotEmpty && colon != full) {
      yield colon;
    }

    final paren = rawTitle.split('(').first.trim();
    if (paren.isNotEmpty && paren != full) {
      yield paren;
    }

    final seasonStripped = rawTitle
        .replaceAll(RegExp(r'\bseason\s+\d+\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bpart\s+\d+\b', caseSensitive: false), '')
        .trim();
    if (seasonStripped.isNotEmpty && seasonStripped != full) {
      yield seasonStripped;
    }

    final subtitleStripped = rawTitle
        .replaceAll(RegExp(r'[-|].*$'), '')
        .trim();
    if (subtitleStripped.isNotEmpty && subtitleStripped != full) {
      yield subtitleStripped;
    }

    final normalizedWords = _normalizeTitle(full)
        .split(' ')
        .where((word) => word.length > 2)
        .toList();
    if (normalizedWords.length >= 2) {
      yield '${normalizedWords[0]} ${normalizedWords[1]}';
    }
    if (normalizedWords.isNotEmpty) {
      yield normalizedWords.first;
    }
  }

  Future<String?> _resolveByRawTitleSearch(
    String query,
    String normalizedOriginal,
  ) async {
    final response = await _dio.get(
      '/manga',
      queryParameters: {
        'title': query.trim(),
        'limit': 10,
        'includes[]': ['cover_art'],
      },
    );

    final List data = response.data['data'] ?? const [];
    String? bestId;
    var bestScore = 0;

    for (final raw in data.cast<Map<String, dynamic>>()) {
      final id = raw['id']?.toString();
      if (id == null || !_uuidPattern.hasMatch(id)) continue;

      final attributes = raw['attributes'] as Map? ?? const {};
      final titleMap = attributes['title'] as Map? ?? const {};
      final candidateTitles = <String>[
        ...titleMap.values.map((value) => value.toString()),
        ...((attributes['altTitles'] as List? ?? const [])
            .whereType<Map>()
            .expand((entry) => entry.values)
            .map((value) => value.toString())),
      ];

      for (final candidate in candidateTitles) {
        final score = _titleMatchScore(normalizedOriginal, candidate);
        if (score > bestScore) {
          bestScore = score;
          bestId = id;
        }
      }
    }

    if (bestId != null) {
      return bestId;
    }

    for (final raw in data.cast<Map<String, dynamic>>()) {
      final id = raw['id']?.toString();
      if (id != null && _uuidPattern.hasMatch(id)) {
        return id;
      }
    }

    return null;
  }

  String _normalizeTitle(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _titleMatchScore(String expected, String candidate) {
    final normalizedCandidate = _normalizeTitle(candidate);
    if (normalizedCandidate.isEmpty) return 0;
    if (normalizedCandidate == expected) return 100;
    if (normalizedCandidate.startsWith(expected) ||
        expected.startsWith(normalizedCandidate)) {
      return 92;
    }
    if (normalizedCandidate.contains(expected) ||
        expected.contains(normalizedCandidate)) {
      return 84;
    }

    final expectedWords = expected.split(' ').where((part) => part.isNotEmpty).toSet();
    final candidateWords =
        normalizedCandidate.split(' ').where((part) => part.isNotEmpty).toSet();
    final sharedWords = expectedWords.intersection(candidateWords).length;
    if (sharedWords == 0) return 0;
    final maxWords = expectedWords.length > candidateWords.length
        ? expectedWords.length
        : candidateWords.length;
    return ((sharedWords / maxWords) * 79).round();
  }

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

  Future<double?> fetchLatestChapter(
    String mangaId, {
    String? coverImageUrl,
    String? title,
  }) async {
    var resolvedId = resolveMangaDexMangaId(
      mangaId,
      coverImageUrl: coverImageUrl,
    );
    if (resolvedId == null && title != null && title.trim().isNotEmpty) {
      resolvedId = await resolveMangaDexMangaIdForTitle(title);
    }
    if (resolvedId == null) {
      return null;
    }
    if (_latestChapterCache.containsKey(resolvedId)) {
      return _latestChapterCache[resolvedId];
    }

    try {
      final response = await _dio.get(
        '/manga/$resolvedId/feed',
        queryParameters: {
          'limit': 1,
          'order[chapter]': 'desc',
          'translatedLanguage[]': ['en'],
        },
      );
      final List data = response.data['data'] ?? const [];
      if (data.isEmpty) {
        _latestChapterCache[resolvedId] = null;
        return null;
      }

      final attributes = (data.first as Map<String, dynamic>)['attributes'] as Map? ?? const {};
      final chapterValue = double.tryParse((attributes['chapter'] ?? '').toString());
      _latestChapterCache[resolvedId] = chapterValue;
      return chapterValue;
    } catch (_) {
      return null;
    }
  }

  Future<List<MangaDexChapter>> fetchChapterFeed(
    String mangaId, {
    String? coverImageUrl,
    String? title,
  }) async {
    var resolvedId = resolveMangaDexMangaId(
      mangaId,
      coverImageUrl: coverImageUrl,
    );
    if (resolvedId == null && title != null && title.trim().isNotEmpty) {
      resolvedId = await resolveMangaDexMangaIdForTitle(title);
    }
    if (resolvedId == null) {
      throw const FormatException('This manga is not linked to a MangaDex entry.');
    }

    final response = await _dio.get(
      '/manga/$resolvedId/feed',
      queryParameters: {
        'translatedLanguage[]': ['en'],
        'order[chapter]': 'asc',
        'limit': 500,
        'offset': 0,
      },
    );

    final List data = response.data['data'] ?? const [];
    final chapters = data
        .map((item) => _mapChapter(item as Map<String, dynamic>))
        .where((chapter) => chapter.pageCount > 0)
        .toList()
      ..sort((a, b) {
        final compare = a.chapterNumber.compareTo(b.chapterNumber);
        if (compare != 0) return compare;
        return a.title.compareTo(b.title);
      });
    return chapters;
  }

  Future<MangaDexChapterPages> fetchChapterPages(
    String chapterId, {
    bool dataSaver = false,
  }) async {
    final primary = await _fetchAtHomePages(chapterId, dataSaver: dataSaver);
    MangaDexAtHomeResponse? fallback;

    try {
      final second = await _fetchAtHomePages(chapterId, dataSaver: dataSaver);
      if (second.baseUrl != primary.baseUrl) {
        fallback = second;
      }
    } catch (_) {
      // Keep the primary node if the fallback probe fails.
    }

    final assets = <MangaDexPageAsset>[];
    for (var i = 0; i < primary.urls.length; i++) {
      assets.add(
        MangaDexPageAsset(
          index: i,
          primaryUrl: primary.urls[i],
          fallbackUrl:
              fallback != null && i < fallback.urls.length ? fallback.urls[i] : null,
        ),
      );
    }

    return MangaDexChapterPages(
      chapterId: chapterId,
      pages: assets,
      hasFallbackNode: fallback != null,
    );
  }

  Future<MangaDexAtHomeResponse> _fetchAtHomePages(
    String chapterId, {
    required bool dataSaver,
  }) async {
    final response = await _dio.get('/at-home/server/$chapterId');
    final baseUrl = (response.data['baseUrl'] ?? '').toString();
    final chapter = response.data['chapter'] as Map? ?? const {};
    final hash = (chapter['hash'] ?? '').toString();
    final fileNames = ((chapter[dataSaver ? 'dataSaver' : 'data']) as List? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    final folder = dataSaver ? 'data-saver' : 'data';
    final urls = fileNames
        .map((fileName) => '$baseUrl/$folder/$hash/$fileName')
        .toList();

    return MangaDexAtHomeResponse(
      baseUrl: baseUrl,
      urls: urls,
    );
  }

  MangaDexChapter _mapChapter(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map? ?? const {};
    final chapterText = (attributes['chapter'] ?? '').toString().trim();
    final chapterNumber = double.tryParse(chapterText) ?? double.infinity;
    final title = (attributes['title'] ?? '').toString().trim();
    final volume = (attributes['volume'] ?? '').toString().trim();
    final pageCount = (attributes['pages'] as num?)?.toInt() ?? 0;

    final labelParts = <String>[
      if (volume.isNotEmpty) 'Vol. $volume',
      if (chapterText.isNotEmpty) 'Ch. $chapterText',
    ];
    final label = labelParts.isEmpty ? 'Chapter' : labelParts.join(' • ');

    return MangaDexChapter(
      id: (json['id'] ?? '').toString(),
      title: title.isEmpty ? label : title,
      chapterLabel: label,
      chapterNumber: chapterNumber,
      chapterText: chapterText,
      volumeText: volume,
      pageCount: pageCount,
    );
  }
}

class MangaDexChapter {
  final String id;
  final String title;
  final String chapterLabel;
  final double chapterNumber;
  final String chapterText;
  final String volumeText;
  final int pageCount;

  const MangaDexChapter({
    required this.id,
    required this.title,
    required this.chapterLabel,
    required this.chapterNumber,
    required this.chapterText,
    required this.volumeText,
    required this.pageCount,
  });
}

class MangaDexPageAsset {
  final int index;
  final String primaryUrl;
  final String? fallbackUrl;
  final String? localPath;

  const MangaDexPageAsset({
    required this.index,
    required this.primaryUrl,
    this.fallbackUrl,
    this.localPath,
  });
}

class MangaDexChapterPages {
  final String chapterId;
  final List<MangaDexPageAsset> pages;
  final bool hasFallbackNode;

  const MangaDexChapterPages({
    required this.chapterId,
    required this.pages,
    required this.hasFallbackNode,
  });
}

class MangaDexAtHomeResponse {
  final String baseUrl;
  final List<String> urls;

  const MangaDexAtHomeResponse({
    required this.baseUrl,
    required this.urls,
  });
}
