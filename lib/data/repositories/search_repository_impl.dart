import 'package:goon_tracker/data/remote/anilist_service.dart';
import 'package:goon_tracker/data/remote/mangadex_service.dart';
import 'package:goon_tracker/data/remote/nhentai_service.dart';
import 'package:goon_tracker/domain/repositories/search_repository.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';

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
    final mangadexResults = await mangadexService.searchManga(
      query,
      page: page,
      perPage: perPage,
      filters: filters,
    );

    if (!_shouldIncludeNhentai(query, filters)) {
      return mangadexResults;
    }

    try {
      final nhentaiResults = await nhentaiService.searchManga(
        query,
        page: page,
        filters: filters,
      );
      return _mergeMangaSearchResults(
        primary: mangadexResults,
        secondary: nhentaiResults,
        perPage: perPage,
      );
    } catch (_) {
      return mangadexResults;
    }
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
    return await mangadexService.fetchTrendingManga(
      page: page,
      perPage: perPage,
      filters: filters,
    );
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
}
