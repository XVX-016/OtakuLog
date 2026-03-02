import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';

enum SearchType { anime, manga }

class SearchState {
  final SearchType type;
  final bool isAdult;
  final String query;

  SearchState({
    this.type = SearchType.anime,
    this.isAdult = false,
    this.query = '',
  });

  SearchState copyWith({
    SearchType? type,
    bool? isAdult,
    String? query,
  }) {
    return SearchState(
      type: type ?? this.type,
      isAdult: isAdult ?? this.isAdult,
      query: query ?? this.query,
    );
  }
}

class SearchNotifier extends AutoDisposeFamilyAsyncNotifier<List<TrackableContent>, SearchType> {
  Timer? _debounceTimer;

  @override
  FutureOr<List<TrackableContent>> build(SearchType arg) async {
    final searchState = ref.watch(searchStateProvider);
    return await fetchTrending(arg, searchState.isAdult);
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final searchState = ref.read(searchStateProvider);
    
    if (query.isEmpty) {
      search('', searchState.isAdult);
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(query, searchState.isAdult);
    });
  }

  Future<void> search(String query, bool isAdult) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(searchRepositoryProvider);
      if (query.isEmpty) {
        return await fetchTrending(arg, isAdult);
      }
      if (arg == SearchType.anime) {
        return await repository.searchAnime(query, isAdult: isAdult);
      } else {
        return await repository.searchManga(query, isAdult: isAdult);
      }
    });
  }

  Future<List<TrackableContent>> fetchTrending(SearchType type, bool isAdult) async {
    final repository = ref.read(searchRepositoryProvider);
    if (type == SearchType.anime) {
      return await repository.getTrendingAnime();
    } else {
      return await repository.getTrendingManga(isAdult: isAdult);
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider.autoDispose.family<SearchNotifier, List<TrackableContent>, SearchType>(
        SearchNotifier.new);

final searchStateProvider = StateProvider<SearchState>((ref) => SearchState());
