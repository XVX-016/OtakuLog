import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/details/widgets/content_preview_sheet.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';
import 'package:goon_tracker/features/search/search_notifier.dart';
import 'package:goon_tracker/features/search/widgets/search_filter_sheet.dart';
import 'package:goon_tracker/features/search/widgets/search_result_card.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _seededDiscover = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(searchNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final libraryIds = ref.watch(combinedLibraryProvider).maybeWhen(
          data: (items) => items.map((item) => item.id).toSet(),
          orElse: () => <String>{},
        );
    _ensureInitialDiscover(state);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, state),
            _buildMediumRow(state),
            Expanded(
              child: state.isLoading && state.results.isEmpty
                  ? _buildLoading()
                  : state.errorMessage != null && state.results.isEmpty
                      ? _buildError(state.errorMessage!)
                      : _buildResults(state, libraryIds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SearchState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search for ${state.filters.medium.name}...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.secondaryText),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchNotifierProvider.notifier)
                                .submitQuery('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close,
                              color: AppTheme.secondaryText),
                        ),
                      IconButton(
                        onPressed: () => ref
                            .read(searchNotifierProvider.notifier)
                            .submitQuery(_searchController.text),
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: AppTheme.primaryText),
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {});
                  ref
                      .read(searchNotifierProvider.notifier)
                      .onQueryChanged(value);
                },
                onSubmitted: (value) => ref
                    .read(searchNotifierProvider.notifier)
                    .submitQuery(value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.elevated,
              foregroundColor: AppTheme.primaryText,
              fixedSize: const Size(52, 52),
            ),
            onPressed: () => _showFilters(context, state.filters),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune_rounded),
                if (state.filters.hasAdvancedFilters)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: CircleAvatar(
                        radius: 4, backgroundColor: AppTheme.accent),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumRow(SearchState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _mediumChip(
              SearchMedium.anime, state.filters.medium == SearchMedium.anime),
          const SizedBox(width: 8),
          _mediumChip(
              SearchMedium.manga, state.filters.medium == SearchMedium.manga),
          const Spacer(),
          if (state.filters.hasAdvancedFilters)
            Flexible(
              child: Text(
                _activeFilterSummary(state.filters),
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediumChip(SearchMedium medium, bool selected) {
    return InkWell(
      onTap: () => ref.read(searchNotifierProvider.notifier).setMedium(medium),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.elevated,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          medium == SearchMedium.anime ? 'ANIME' : 'MANGA',
          style: TextStyle(
            color: selected ? AppTheme.primaryText : AppTheme.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResults(SearchState state, Set<String> libraryIds) {
    if (state.results.isEmpty) {
      if (_isOfflineMessage(state.errorMessage)) {
        return _buildError(state.errorMessage!);
      }
      return GTEmptyState(
        icon: Icons.explore_outlined,
        title: state.query.trim().isEmpty
            ? 'Nothing to discover yet'
            : 'No results found',
        description: state.query.trim().isEmpty
            ? 'Try changing your filters or switching medium.'
            : 'Adjust filters, switch medium, or try a different title.',
      );
    }

    final results = state.results
        .map((item) => item.copyWith(inLibrary: libraryIds.contains(item.id)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            state.query.trim().isEmpty ? 'DISCOVER' : 'RESULTS',
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: results.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = results[index];
              return SearchResultCard(
                item: item,
                onTap: () => _showPreview(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.elevated,
        highlightColor: AppTheme.surface,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 152,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOfflineMessage(message)
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline,
              color: _isOfflineMessage(message) ? Colors.orange : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  ref.read(searchNotifierProvider.notifier).retry(),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, SearchFilters filters) async {
    final nextFilters = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterSheet(initialFilters: filters),
    );

    if (nextFilters != null) {
      await ref
          .read(searchNotifierProvider.notifier)
          .updateFilters(nextFilters);
    }
  }

  void _showPreview(BuildContext context, SearchResultItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentPreviewSheet(searchItem: item),
    );
  }

  void _ensureInitialDiscover(SearchState state) {
    if (_seededDiscover ||
        state.isLoading ||
        state.results.isNotEmpty ||
        state.errorMessage != null ||
        state.currentPage > 0) {
      return;
    }
    _seededDiscover = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchNotifierProvider.notifier).refresh();
    });
  }

  String _activeFilterSummary(SearchFilters filters) {
    final pieces = <String>[
      if (filters.adultMode != AdultMode.off) _adultLabel(filters.adultMode),
      if (filters.status != ContentStatusFilter.any) filters.status.name,
      if (filters.sort != SearchSort.trending) filters.sort.name,
      if (filters.includedTags.isNotEmpty)
        '${filters.includedTags.length} tags',
    ];
    return pieces.join(' | ');
  }

  String _adultLabel(AdultMode mode) {
    switch (mode) {
      case AdultMode.off:
        return 'Off';
      case AdultMode.mixed:
        return 'Mixed';
      case AdultMode.explicitOnly:
        return 'Explicit';
    }
  }

  bool _isOfflineMessage(String? message) {
    if (message == null) return false;
    return message.toLowerCase().contains('no network');
  }
}
