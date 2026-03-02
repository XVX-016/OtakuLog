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

class SearchNotifier extends AutoDisposeAsyncNotifier<List<TrackableContent>> {
  Timer? _debounceTimer;

  @override
  FutureOr<List<TrackableContent>> build() {
    return [];
  }

  void onQueryChanged(String query, SearchType type, bool isAdult) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search(query, type, isAdult);
    });
  }

  Future<void> search(String query, SearchType type, bool isAdult) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(searchRepositoryProvider);
      if (type == SearchType.anime) {
        return await repository.searchAnime(query, isAdult: isAdult);
      } else {
        return await repository.searchManga(query, isAdult: isAdult);
      }
    });
  }
}

final searchNotifierProvider =
    AsyncNotifierProvider.autoDispose<SearchNotifier, List<TrackableContent>>(
        SearchNotifier.new);

final searchStateProvider = StateProvider<SearchState>((ref) => SearchState());
