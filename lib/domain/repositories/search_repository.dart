import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

abstract class SearchRepository {
  Future<List<SearchResultItem>> searchAnime(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  });

  Future<List<SearchResultItem>> searchManga(
    String query, {
    required int page,
    required int perPage,
    required SearchFilters filters,
  });

  Future<List<SearchResultItem>> getTrendingAnime({
    required int page,
    required int perPage,
    required SearchFilters filters,
  });

  Future<List<SearchResultItem>> getTrendingManga({
    required int page,
    required int perPage,
    required SearchFilters filters,
  });
}
