enum SearchMedium { anime, manga }

enum AdultMode { off, mixed, explicitOnly }

enum SearchSort { trending, popular, updated, score }

enum ContentStatusFilter { any, airing, finished, ongoing, completed }

const List<String> kCuratedSearchTags = [
  'Ecchi',
  'Harem',
  'Hentai',
  'Nudity',
  'Romance',
  'Action',
  'Comedy',
  'Drama',
  'Fantasy',
  'Horror',
];

class SearchFilters {
  final SearchMedium medium;
  final AdultMode adultMode;
  final Set<String> includedTags;
  final Set<String> excludedTags;
  final ContentStatusFilter status;
  final SearchSort sort;

  const SearchFilters({
    this.medium = SearchMedium.anime,
    this.adultMode = AdultMode.off,
    this.includedTags = const {},
    this.excludedTags = const {},
    this.status = ContentStatusFilter.any,
    this.sort = SearchSort.trending,
  });

  SearchFilters copyWith({
    SearchMedium? medium,
    AdultMode? adultMode,
    Set<String>? includedTags,
    Set<String>? excludedTags,
    ContentStatusFilter? status,
    SearchSort? sort,
  }) {
    return SearchFilters(
      medium: medium ?? this.medium,
      adultMode: adultMode ?? this.adultMode,
      includedTags: includedTags ?? this.includedTags,
      excludedTags: excludedTags ?? this.excludedTags,
      status: status ?? this.status,
      sort: sort ?? this.sort,
    );
  }

  SearchFilters clearAdvanced() {
    return SearchFilters(
      medium: medium,
      adultMode: AdultMode.off,
      sort: SearchSort.trending,
    );
  }

  bool get hasAdvancedFilters =>
      adultMode != AdultMode.off ||
      status != ContentStatusFilter.any ||
      sort != SearchSort.trending ||
      includedTags.isNotEmpty ||
      excludedTags.isNotEmpty;
}
