import 'package:dio/dio.dart';
import 'package:goon_tracker/core/utils/text_sanitizer.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';

class AnilistService {
  final Dio _dio;

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

  static const String _mediaFields = r'''
    id
    title { romaji english native }
    coverImage { large }
    episodes
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

  Future<List<SearchResultItem>> _fetchAnimePage({
    String query = '',
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    final variables = _buildVariables(query, page, perPage, filters);
    final response = await _dio.post(
      '',
      data: {
        'query': _buildQuery(),
        'variables': variables,
      },
    );

    final List mediaList = response.data['data']['Page']['media'] ?? [];
    final mapped =
        mediaList.map((item) => _mapToResult(item as Map<String, dynamic>)).toList();
    return _applyLocalTagFiltering(mapped, filters);
  }

  Map<String, dynamic> _buildVariables(
    String query,
    int page,
    int perPage,
    SearchFilters filters,
  ) {
    final includedGenres = filters.includedTags.where(_genreTags.contains).toList();
    final excludedGenres = filters.excludedTags.where(_genreTags.contains).toList();
    final includedTags = _buildAniListTags(filters.includedTags, filters.adultMode == AdultMode.explicitOnly);
    final excludedTags = _buildAniListTags(filters.excludedTags, filters.adultMode == AdultMode.off);

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
    };
  }

  List<String> _buildAniListTags(Set<String> tags, bool includeAdultPreset) {
    final result = <String>{...tags.where((tag) => !_genreTags.contains(tag))};
    if (includeAdultPreset) {
      result.addAll(_adultTags);
    }
    if (!includeAdultPreset && result.isEmpty) {
      return const [];
    }
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
      final included = filters.includedTags.every(
        (tag) => lowerTags.contains(tag.toLowerCase()),
      );
      final excluded = filters.excludedTags.any(
        (tag) => lowerTags.contains(tag.toLowerCase()),
      );
      return included && !excluded;
    }).toList();
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

  String _buildQuery() {
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
            type: ANIME,
            search: \$search,
            sort: \$sort,
            status: \$status,
            isAdult: \$isAdult,
            genre_in: \$genreIn,
            genre_not_in: \$genreNotIn,
            tag_in: \$tagIn,
            tag_not_in: \$tagNotIn
          ) {
            $_mediaFields
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
      tags: [...genres, ...tagNames].toSet().take(6).toList(),
      description: description,
      score: resolvedScore,
      isAdult: json['isAdult'] == true,
      statusLabel: json['status']?.toString(),
      totalCount: content.totalEpisodes > 0 ? content.totalEpisodes : null,
    );
  }

  DateTime _updatedAt(dynamic value) {
    if (value is int && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.now();
  }
}
