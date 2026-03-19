import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/domain/repositories/search_repository.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class SearchState {
  final String query;
  final SearchFilters filters;
  final List<SearchResultItem> results;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const SearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.results = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<SearchResultItem>? results,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SearchNotifier extends AutoDisposeNotifier<SearchState> {
  static const int _pageSize = 25;
  Timer? _debounce;
  bool _seededDefaults = false;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_seedDefaultsIfNeeded);
    return const SearchState();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      refresh(query: query);
    });
  }

  Future<void> submitQuery(String query) async {
    _debounce?.cancel();
    await refresh(query: query);
  }

  Future<void> setMedium(SearchMedium medium) async {
    if (state.filters.medium == medium) return;
    await updateFilters(state.filters.copyWith(medium: medium));
  }

  Future<void> updateFilters(SearchFilters filters) async {
    await refresh(filters: filters);
  }

  Future<void> refresh({
    String? query,
    SearchFilters? filters,
  }) async {
    state = state.copyWith(
      query: query ?? state.query,
      filters: filters ?? state.filters,
      results: const [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      currentPage: 0,
      clearError: true,
    );
    await _fetchPage(page: 1, append: false);
  }

  Future<void> retry() => refresh();

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _fetchPage(page: state.currentPage + 1, append: true);
  }

  Future<void> _fetchPage({
    required int page,
    required bool append,
  }) async {
    final repository = ref.read(searchRepositoryProvider);
    final trimmedQuery = state.query.trim();

    try {
      final results = trimmedQuery.isEmpty
          ? await _discover(repository, page)
          : await _search(repository, trimmedQuery, page);

      state = state.copyWith(
        results: append ? [...state.results, ...results] : results,
        isLoading: false,
        isLoadingMore: false,
        hasMore: results.length == _pageSize,
        currentPage: page,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> _seedDefaultsIfNeeded() async {
    if (_seededDefaults) return;
    _seededDefaults = true;
    final defaults = await ref.read(searchDefaultsProvider.future);
    final isStillInitial = state.currentPage == 0 &&
        state.query.trim().isEmpty &&
        state.results.isEmpty &&
        !state.isLoading &&
        !state.isLoadingMore;
    if (!isStillInitial) return;
    await refresh(filters: defaults);
  }

  Future<List<SearchResultItem>> _discover(
      SearchRepository repository, int page) {
    if (state.filters.medium == SearchMedium.anime) {
      return repository.getTrendingAnime(
        page: page,
        perPage: _pageSize,
        filters: state.filters,
      );
    }

    return repository.getTrendingManga(
      page: page,
      perPage: _pageSize,
      filters: state.filters,
    );
  }

  Future<List<SearchResultItem>> _search(
    SearchRepository repository,
    String query,
    int page,
  ) {
    if (state.filters.medium == SearchMedium.anime) {
      return repository.searchAnime(
        query,
        page: page,
        perPage: _pageSize,
        filters: state.filters,
      );
    }

    return repository.searchManga(
      query,
      page: page,
      perPage: _pageSize,
      filters: state.filters,
    );
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'No network connection. Reconnect to load search and trending.';
      }
      if (error.type == DioExceptionType.unknown) {
        final lowerMessage = (error.message ?? '').toLowerCase();
        if (lowerMessage.contains('socketexception') ||
            lowerMessage.contains('connection') ||
            lowerMessage.contains('network') ||
            lowerMessage.contains('timed out') ||
            lowerMessage.contains('handshake')) {
          return 'No network connection. Reconnect to load search and trending.';
        }
        return 'Search request failed. Please try again.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return 'Search is unavailable right now ($statusCode). Please try again.';
      }
    }
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('connection') ||
        message.contains('network')) {
      return 'No network connection. Reconnect to load search and trending.';
    }
    return message;
  }
}

final searchNotifierProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
        SearchNotifier.new);
