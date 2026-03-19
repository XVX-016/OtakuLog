import 'package:otakulog/data/remote/anilist_service.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/data/remote/nhentai_service.dart';
import 'package:otakulog/domain/repositories/search_repository.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class SearchRepositoryImpl implements SearchRepository {
  final AnilistService anilistService;
  final MangadexService mangadexService;
  final NhentaiService nhentaiService;

  SearchRepositoryImpl({
    required this.anilistService,
    required this.mangadexService,
    required this.nhentaiService,
  });

  @override
  Future<List<SearchResultItem>> searchAnime(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return await anilistService.searchAnime(
      query,
      page: page,
      perPage: perPage,
      filters: filters,
    );
  }

  @override
  Future<List<SearchResultItem>> searchManga(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    List<SearchResultItem> mangadexResults = const [];
    Object? mangadexError;
    List<SearchResultItem> fallbackResults = const [];

    try {
      mangadexResults = await mangadexService.searchManga(
        query,
        page: page,
        perPage: perPage,
        filters: filters,
      );
    } catch (error) {
      mangadexError = error;
    }

    if (!_shouldIncludeNhentai(query, filters)) {
      if (mangadexResults.isEmpty) {
        try {
          fallbackResults = await anilistService.searchManga(
            query,
            page: page,
            perPage: perPage,
            filters: filters,
          );
        } catch (_) {}
      }
      if (mangadexError != null) {
        if (fallbackResults.isNotEmpty) {
          return _applyMangaCategoryFilter(fallbackResults, filters);
        }
        throw mangadexError;
      }
      return _applyMangaCategoryFilter(
        mangadexResults.isNotEmpty ? mangadexResults : fallbackResults,
        filters,
      );
    }

    List<SearchResultItem> nhentaiResults = const [];
    try {
      nhentaiResults = await nhentaiService.searchManga(
        query,
        page: page,
        filters: filters,
      );
    } catch (_) {
      if (mangadexError != null && nhentaiResults.isEmpty) {
        throw mangadexError;
      }
      return _applyMangaCategoryFilter(mangadexResults, filters);
    }

    if (mangadexError != null) {
      try {
        fallbackResults = await anilistService.searchManga(
          query,
          page: page,
          perPage: perPage,
          filters: filters,
        );
      } catch (_) {}
      if (nhentaiResults.isNotEmpty) {
        return _applyMangaCategoryFilter(
          _mergeMangaSearchResults(
          primary: fallbackResults,
          secondary: nhentaiResults,
          perPage: perPage,
          ),
          filters,
        );
      }
      if (fallbackResults.isNotEmpty) {
        return _applyMangaCategoryFilter(fallbackResults, filters);
      }
      return _applyMangaCategoryFilter(mangadexResults, filters);
    }

    final baseResults = mangadexResults.isNotEmpty
        ? mangadexResults
        : await _safeAniListMangaFallback(
            query,
            page: page,
            perPage: perPage,
            filters: filters,
          );

    return _applyMangaCategoryFilter(
      _mergeMangaSearchResults(
        primary: baseResults,
        secondary: nhentaiResults,
        perPage: perPage,
      ),
      filters,
    );
  }

  @override
  Future<List<SearchResultItem>> getTrendingAnime({
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    return await anilistService.fetchTrendingAnime(
      page: page,
      perPage: perPage,
      filters: filters,
    );
  }

  @override
  Future<List<SearchResultItem>> getTrendingManga({
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    try {
      final results = await mangadexService.fetchTrendingManga(
        page: page,
        perPage: perPage,
        filters: filters,
      );
      if (results.isNotEmpty) {
        return _applyMangaCategoryFilter(results, filters);
      }
    } catch (_) {}

    return _applyMangaCategoryFilter(
      await anilistService.fetchTrendingManga(
      page: page,
      perPage: perPage,
      filters: filters,
      ),
      filters,
    );
  }

  List<SearchResultItem> _applyMangaCategoryFilter(
    List<SearchResultItem> items,
    SearchFilters filters,
  ) {
    if (filters.medium != SearchMedium.manga ||
        filters.mangaCategory == MangaCategoryFilter.any) {
      return items;
    }

    return items
        .where((item) => item.mangaCategory == filters.mangaCategory)
        .toList();
  }

  bool _shouldIncludeNhentai(String query, SearchFilters filters) {
    return query.trim().isNotEmpty &&
        (filters.adultMode == AdultMode.explicitOnly ||
            filters.includedTags.contains('Hentai'));
  }

  List<SearchResultItem> _mergeMangaSearchResults({
    required List<SearchResultItem> primary,
    required List<SearchResultItem> secondary,
    required int perPage,
  }) {
    if (secondary.isEmpty) return primary;

    final primaryQuota = (perPage * 0.6).round();
    final secondaryQuota = perPage - primaryQuota;
    final merged = <String, SearchResultItem>{};

    void addItems(List<SearchResultItem> items, int limit) {
      for (final item in items.take(limit)) {
        merged.putIfAbsent(item.id, () => item);
      }
    }

    addItems(primary, primaryQuota);
    addItems(secondary, secondaryQuota);

    for (final item in primary) {
      if (merged.length >= perPage) break;
      merged.putIfAbsent(item.id, () => item);
    }
    for (final item in secondary) {
      if (merged.length >= perPage) break;
      merged.putIfAbsent(item.id, () => item);
    }

    return merged.values.toList();
  }

  Future<List<SearchResultItem>> _safeAniListMangaFallback(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  }) async {
    try {
      return await anilistService.searchManga(
        query,
        page: page,
        perPage: perPage,
        filters: filters,
      );
    } catch (_) {
      return const [];
    }
  }
}
