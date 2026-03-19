import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/repositories/search_repository.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';
import 'package:goon_tracker/features/search/search_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late _MockSearchRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<SearchState> subscription;

  setUp(() {
    registerFallbackValue(const SearchFilters());
    repository = _MockSearchRepository();
    container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repository),
        searchDefaultsProvider.overrideWith((ref) async => const SearchFilters()),
      ],
    );
    subscription = container.listen(searchNotifierProvider, (_, __) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  SearchNotifier notifier() => container.read(searchNotifierProvider.notifier);

  List<SearchResultItem> animeResults(int count, {String prefix = 'anime'}) {
    return List.generate(
      count,
      (index) {
        final anime = AnimeEntity(
          id: '$prefix-$index',
          title: 'Anime $index',
          coverImage: '',
          totalEpisodes: 12,
          currentEpisode: 0,
          status: AnimeStatus.watching,
          genres: const ['Action'],
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
        return SearchResultItem(
          id: anime.id,
          content: anime,
          medium: SearchMedium.anime,
          tags: const ['Action'],
          totalCount: 12,
        );
      },
    );
  }

  test('initial build loads discover page 1', () async {
    when(
      () => repository.getTrendingAnime(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(25));

    container.read(searchNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = container.read(searchNotifierProvider);
    expect(state.results, hasLength(25));
    expect(state.currentPage, 1);
    expect(state.filters.medium, SearchMedium.anime);
  });

  test('query refresh replaces results', () async {
    when(
      () => repository.getTrendingAnime(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(25, prefix: 'discover'));
    when(
      () => repository.searchAnime(
        'naruto',
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(3, prefix: 'search'));

    container.read(searchNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await notifier().refresh(query: 'naruto');

    final state = container.read(searchNotifierProvider);
    expect(state.query, 'naruto');
    expect(state.results, hasLength(3));
    expect(state.results.first.id, 'search-0');
  });

  test('medium switch resets and fetches manga discover', () async {
    when(
      () => repository.getTrendingAnime(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(1));
    when(
      () => repository.getTrendingManga(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(4, prefix: 'manga'));

    container.read(searchNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await notifier().setMedium(SearchMedium.manga);

    final state = container.read(searchNotifierProvider);
    expect(state.filters.medium, SearchMedium.manga);
    expect(state.results, hasLength(4));
  });

  test('updating filters triggers fresh search', () async {
    when(
      () => repository.getTrendingAnime(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(5, prefix: 'filtered'));
    when(
      () => repository.searchAnime(
        'berserk',
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(2, prefix: 'berserk'));

    container.read(searchNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await notifier().refresh(query: 'berserk');
    await notifier().updateFilters(
      const SearchFilters(medium: SearchMedium.anime, adultMode: AdultMode.explicitOnly),
    );

    final state = container.read(searchNotifierProvider);
    expect(state.filters.adultMode, AdultMode.explicitOnly);
    expect(state.query, 'berserk');
    expect(state.results, hasLength(2));
  });

  test('loadMore appends results and increments page', () async {
    when(
      () => repository.getTrendingAnime(
        page: 1,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(25, prefix: 'page1'));
    when(
      () => repository.getTrendingAnime(
        page: 2,
        perPage: 25,
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => animeResults(10, prefix: 'page2'));

    container.read(searchNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await notifier().loadMore();

    final state = container.read(searchNotifierProvider);
    expect(state.results, hasLength(35));
    expect(state.currentPage, 2);
    expect(state.hasMore, isFalse);
  });
}
