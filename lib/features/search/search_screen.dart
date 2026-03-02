import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/search/search_notifier.dart';
import 'package:goon_tracker/features/details/widgets/content_preview_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchNotifierProvider);
    final searchState = ref.watch(searchStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, ref, searchState),
            _buildFilters(context, ref, searchState),
            Expanded(
              child: searchResults.when(
                data: (results) => _buildResultsList(results, _searchController.text.isEmpty),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, SearchState searchState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            hintText: 'Search for ${searchState.type.name}...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) {
            ref.read(searchNotifierProvider.notifier).onQueryChanged(
                  value,
                  searchState.type,
                  searchState.isAdult,
                );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, SearchState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('ANIME', state.type == SearchType.anime, () {
            ref.read(searchStateProvider.notifier).state = state.copyWith(type: SearchType.anime);
            ref.read(searchNotifierProvider.notifier).search(_searchController.text, SearchType.anime, state.isAdult);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('MANGA', state.type == SearchType.manga, () {
            ref.read(searchStateProvider.notifier).state = state.copyWith(type: SearchType.manga);
            ref.read(searchNotifierProvider.notifier).search(_searchController.text, SearchType.manga, state.isAdult);
          }),
          const Spacer(),
          const Text('18+', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText)),
          const SizedBox(width: 4),
          Switch.adaptive(
            value: state.isAdult,
            activeColor: AppTheme.accent,
            onChanged: (val) {
              ref.read(searchStateProvider.notifier).state = state.copyWith(isAdult: val);
              ref.read(searchNotifierProvider.notifier).search(_searchController.text, state.type, val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryText : AppTheme.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(List<TrackableContent> results, bool isTrending) {
    if (results.isEmpty) {
      return GTEmptyState(
        icon: Icons.sentiment_dissatisfied,
        title: 'No results found',
        description: 'Try searching for something else or adjusting your filters.',
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isTrending)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'TRENDING NOW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final item = results[index];
              return _buildResultCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, TrackableContent item) {
    return InkWell(
      onTap: () => _showPreview(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.coverImage,
                width: 85,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.elevated, width: 85, height: 120),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item is AnimeEntity ? 'Anime • ${item.totalEpisodes} eps' : 'Manga • ${item.totalProgress} chapters',
                    style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (item.genres.isNotEmpty)
                    Text(
                      item.genres.take(3).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.accent.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
              onPressed: () => _showPreview(context, item),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, TrackableContent item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContentPreviewSheet(content: item),
    );
  }


  Future<void> _addToLibrary(BuildContext context, TrackableContent item) async {
    try {
      if (item is AnimeEntity) {
        await ref.read(animeRepositoryProvider).saveAnime(item);
      } else if (item is MangaEntity) {
        await ref.read(mangaRepositoryProvider).saveManga(item);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${item.title} to Library')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
