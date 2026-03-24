import 'package:dio/dio.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class AnilistService {
  final Dio _dio;
  final Map<String, int?> _latestReleasedEpisodeCache = {};

  static const List<String> _adultTags = [
    'Ecchi',
    'Hentai',
    'Sexual Content',
    'Nudity',
    'Harem',
    'Reverse Harem',
    'Fan Service',
  ];

  static const Set<String> _genreTags = {
    'Romance',
    'Action',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
  };

  AnilistService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));

  static const String _animeFields = r'''
    id
    title { romaji english native }
    coverImage { large }
    episodes
    nextAiringEpisode { episode airingAt }
    genres
    description(asHtml: false)
    averageScore
    updatedAt
    isAdult
    popularity
    status
    tags { name }
  ''';

  static const String _mangaFields = r'''
    id
    title { romaji english native }
    coverImage { large }
    chapters
    countryOfOrigin
    genres
    description(asHtml: false)
    averageScore
    updatedAt
    isAdult
    popularity
    status
    tags { name }
  ''';

  Future<List<SearchResultItem>> searchAnime(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return _fetchAnimePage(
      query: query,
      page: page,
      perPage: perPage,
      filters: filters,
    );
  }

  Future<List<SearchResultItem>> fetchTrendingAnime({
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return _fetchAnimePage(
      page: page,
      perPage: perPage,
      filters: filters.copyWith(sort: filters.sort),
    );
  }

  Future<List<SearchResultItem>> searchManga(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return _fetchMangaPage(
      query: query,
      page: page,
      perPage: perPage,
      filters: filters,
    );
  }

  Future<List<SearchResultItem>> fetchTrendingManga({
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return _fetchMangaPage(
      page: page,
      perPage: perPage,
      filters: filters.copyWith(sort: filters.sort),
    );
  }

  Future<List<SearchResultItem>> _fetchAnimePage({
    String query = '',
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    final variables = _buildVariables(query, page, perPage, filters);
    final filtered = await _requestAndFilter(
      variables,
      filters,
      type: 'ANIME',
      mediaFields: _animeFields,
      mapper: _mapToResult,
    );
    if (filtered.isNotEmpty || filters.adultMode != AdultMode.explicitOnly) {
      return filtered;
    }

    final fallbackVariables = Map<String, dynamic>.from(variables)
      ..remove('tagIn')
      ..remove('tagNotIn')
      ..['isAdult'] = true;
    return _requestAndFilter(
      fallbackVariables,
      filters,
      type: 'ANIME',
      mediaFields: _animeFields,
      mapper: _mapToResult,
    );
  }

  Future<List<SearchResultItem>> _fetchMangaPage({
    String query = '',
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    final variables = _buildVariables(query, page, perPage, filters);
    final filtered = await _requestAndFilter(
      variables,
      filters,
      type: 'MANGA',
      mediaFields: _mangaFields,
      mapper: _mapMangaResult,
    );
    if (filtered.isNotEmpty || filters.adultMode != AdultMode.explicitOnly) {
      return filtered;
    }

    final fallbackVariables = Map<String, dynamic>.from(variables)
      ..remove('tagIn')
      ..remove('tagNotIn')
      ..['isAdult'] = true;
    return _requestAndFilter(
      fallbackVariables,
      filters,
      type: 'MANGA',
      mediaFields: _mangaFields,
      mapper: _mapMangaResult,
    );
  }

  Map<String, dynamic> _buildVariables(
    String query,
    int page,
    int perPage,
    SearchFilters filters,
  ) {
    final includedGenres = filters.includedTags.where(_genreTags.contains).toList();
    final excludedGenres = filters.excludedTags.where(_genreTags.contains).toList();
    final includedTags = _buildAniListTags(filters.includedTags);
    final excludedTags = _buildAniListTags(filters.excludedTags);

    return <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (query.trim().isNotEmpty) 'search': query.trim(),
      'sort': [_mapSort(filters.sort)],
      if (filters.status != ContentStatusFilter.any) 'status': _mapAnimeStatus(filters.status),
      if (includedGenres.isNotEmpty) 'genreIn': includedGenres,
      if (excludedGenres.isNotEmpty) 'genreNotIn': excludedGenres,
      if (includedTags.isNotEmpty) 'tagIn': includedTags,
      if (excludedTags.isNotEmpty) 'tagNotIn': excludedTags,
      if (filters.adultMode == AdultMode.off) 'isAdult': false,
      if (filters.adultMode == AdultMode.explicitOnly) 'isAdult': true,
    };
  }

  List<String> _buildAniListTags(Set<String> tags) {
    final result = <String>{...tags.where((tag) => !_genreTags.contains(tag))};
    return result.toList();
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
      final included = filters.includedTags.isEmpty ||
          filters.includedTags.any(
            (tag) => lowerTags.contains(tag.toLowerCase()),
          );
      final excluded = filters.excludedTags.any(
        (tag) => lowerTags.contains(tag.toLowerCase()),
      );
      return included && !excluded;
    }).toList();
  }

  Future<List<SearchResultItem>> _requestAndFilter(
    Map<String, dynamic> variables,
    SearchFilters filters,
      {required String type,
      required String mediaFields,
      required SearchResultItem Function(Map<String, dynamic>) mapper}) async {
    final response = await _dio.post(
      '',
      data: {
        'query': _buildQuery(type: type, mediaFields: mediaFields),
        'variables': variables,
      },
    );

    final List mediaList = response.data['data']['Page']['media'] ?? [];
    final mapped = mediaList.map((item) => mapper(item as Map<String, dynamic>)).toList();
    return _applyLocalTagFiltering(mapped, filters);
  }

  String _mapSort(SearchSort sort) {
    switch (sort) {
      case SearchSort.trending:
        return 'TRENDING_DESC';
      case SearchSort.popular:
        return 'POPULARITY_DESC';
      case SearchSort.updated:
        return 'UPDATED_AT_DESC';
      case SearchSort.score:
        return 'SCORE_DESC';
    }
  }

  String _mapAnimeStatus(ContentStatusFilter status) {
    switch (status) {
      case ContentStatusFilter.airing:
        return 'RELEASING';
      case ContentStatusFilter.finished:
      case ContentStatusFilter.completed:
        return 'FINISHED';
      case ContentStatusFilter.any:
      case ContentStatusFilter.ongoing:
        return 'RELEASING';
    }
  }

  String _buildQuery({required String type, required String mediaFields}) {
    return '''
      query (
        \$page: Int,
        \$perPage: Int,
        \$search: String,
        \$sort: [MediaSort],
        \$status: MediaStatus,
        \$isAdult: Boolean,
        \$genreIn: [String],
        \$genreNotIn: [String],
        \$tagIn: [String],
        \$tagNotIn: [String]
        ) {
          Page(page: \$page, perPage: \$perPage) {
            media(
            type: $type,
            search: \$search,
            sort: \$sort,
            status: \$status,
            isAdult: \$isAdult,
            genre_in: \$genreIn,
            genre_not_in: \$genreNotIn,
            tag_in: \$tagIn,
            tag_not_in: \$tagNotIn
          ) {
            $mediaFields
          }
        }
      }
    ''';
  }

  SearchResultItem _mapToResult(Map<String, dynamic> json) {
    final titleData = json['title'] as Map? ?? const {};
    final resolvedTitle = (titleData['english'] ?? titleData['romaji'] ?? titleData['native'] ?? 'Unknown').toString();
    final coverImage = json['coverImage'] as Map? ?? const {};
    final score = json['averageScore'];
    final resolvedScore = score is num ? score.toDouble() / 10.0 : null;
    final genres = List<String>.from(json['genres'] ?? const []);
    final tagNames = (json['tags'] as List? ?? const [])
        .map((tag) => ((tag as Map?)?['name'] ?? '').toString())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final allTags = [...genres, ...tagNames].toSet().toList();

    final description = stripHtmlTags(json['description']?.toString());
    final content = AnimeEntity(
      id: (json['id'] ?? '').toString(),
      title: resolvedTitle,
      coverImage: (coverImage['large'] ?? '').toString(),
      totalEpisodes: json['episodes'] is int ? json['episodes'] as int : 0,
      currentEpisode: 0,
      status: AnimeStatus.watching,
      rating: resolvedScore,
      genres: genres,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: _updatedAt(json['updatedAt']),
    );

    return SearchResultItem(
      id: content.id,
      content: content,
      medium: SearchMedium.anime,
      tags: allTags,
      description: description,
      score: resolvedScore,
      isAdult: json['isAdult'] == true,
      statusLabel: json['status']?.toString(),
      sourceLabel: 'AniList',
      totalCount: content.totalEpisodes > 0 ? content.totalEpisodes : null,
    );
  }

  SearchResultItem _mapMangaResult(Map<String, dynamic> json) {
    final titleData = json['title'] as Map? ?? const {};
    final resolvedTitle =
        (titleData['english'] ?? titleData['romaji'] ?? titleData['native'] ?? 'Unknown')
            .toString();
    final coverImage = json['coverImage'] as Map? ?? const {};
    final score = json['averageScore'];
    final resolvedScore = score is num ? score.toDouble() / 10.0 : null;
    final genres = List<String>.from(json['genres'] ?? const []);
    final tagNames = (json['tags'] as List? ?? const [])
        .map((tag) => ((tag as Map?)?['name'] ?? '').toString())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final allTags = [...genres, ...tagNames].toSet().toList();
    final description = stripHtmlTags(json['description']?.toString());

    final content = MangaEntity(
      id: (json['id'] ?? '').toString(),
      title: resolvedTitle,
      coverImage: (coverImage['large'] ?? '').toString(),
      totalChapters: json['chapters'] is int ? json['chapters'] as int : 0,
      currentChapter: 0,
      status: MangaStatus.reading,
      rating: resolvedScore,
      genres: genres,
      description: description,
      isAdult: json['isAdult'] == true,
      createdAt: DateTime.now(),
      updatedAt: _updatedAt(json['updatedAt']),
    );

    return SearchResultItem(
      id: content.id,
      content: content,
      medium: SearchMedium.manga,
      tags: allTags,
      description: description,
      score: resolvedScore,
      isAdult: content.isAdult,
      statusLabel: json['status']?.toString(),
      sourceLabel: 'AniList',
      mangaCategory: _mapAniListMangaCategory(
        json['countryOfOrigin']?.toString(),
      ),
      totalCount: content.totalChapters > 0 ? content.totalChapters : null,
    );
  }

  MangaCategoryFilter _mapAniListMangaCategory(String? countryCode) {
    switch ((countryCode ?? '').toUpperCase()) {
      case 'KR':
        return MangaCategoryFilter.manhwa;
      case 'CN':
      case 'TW':
      case 'HK':
        return MangaCategoryFilter.manhua;
      case 'JP':
      default:
        return MangaCategoryFilter.manga;
    }
  }

  DateTime _updatedAt(dynamic value) {
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.now();
  }

  Future<int?> fetchLatestReleasedEpisode(String animeId) async {
    if (_latestReleasedEpisodeCache.containsKey(animeId)) {
      return _latestReleasedEpisodeCache[animeId];
    }

    final response = await _dio.post(
      '',
      data: {
        'query': r'''
          query ($id: Int) {
            Media(id: $id, type: ANIME) {
              episodes
              nextAiringEpisode {
                episode
              }
              status
            }
          }
        ''',
        'variables': {
          'id': int.tryParse(animeId),
        },
      },
    );

    final media = response.data['data']?['Media'] as Map? ?? const {};
    final episodes = (media['episodes'] as num?)?.toInt();
    if (episodes != null && episodes > 0) {
      _latestReleasedEpisodeCache[animeId] = episodes;
      return episodes;
    }

    final nextAiring = (media['nextAiringEpisode'] as Map?)?['episode'];
    final nextAiringEpisode = (nextAiring as num?)?.toInt();
    final latestReleased =
        nextAiringEpisode != null && nextAiringEpisode > 1 ? nextAiringEpisode - 1 : null;
    _latestReleasedEpisodeCache[animeId] = latestReleased;
    return latestReleased;
  }
}
