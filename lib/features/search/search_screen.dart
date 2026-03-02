import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/search/search_notifier.dart';

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
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search content...',
            prefixIcon: Icon(Icons.search),
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
      body: Column(
        children: [
          _buildFilters(context, ref, searchState),
          Expanded(
            child: searchResults.when(
              data: (results) => _buildResultsList(results),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, SearchState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Anime'),
            selected: state.type == SearchType.anime,
            onSelected: (val) {
              if (val) {
                ref.read(searchStateProvider.notifier).state =
                    state.copyWith(type: SearchType.anime);
                ref.read(searchNotifierProvider.notifier).search(
                    _searchController.text, SearchType.anime, state.isAdult);
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Manga'),
            selected: state.type == SearchType.manga,
            onSelected: (val) {
              if (val) {
                ref.read(searchStateProvider.notifier).state =
                    state.copyWith(type: SearchType.manga);
                ref.read(searchNotifierProvider.notifier).search(
                    _searchController.text, SearchType.manga, state.isAdult);
              }
            },
          ),
          const Spacer(),
          const Text('18+', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
          Switch(
            value: state.isAdult,
            activeColor: AppTheme.accent,
            onChanged: (val) {
              ref.read(searchStateProvider.notifier).state =
                  state.copyWith(isAdult: val);
              ref.read(searchNotifierProvider.notifier).search(
                  _searchController.text, state.type, val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<TrackableContent> results) {
    if (results.isEmpty) {
      return GTEmptyState(
        icon: Icons.sentiment_dissatisfied,
        title: 'No results found',
        description: 'Try searching for something else or adjusting your filters.',
      );
    }
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultCard(context, item);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, TrackableContent item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.coverImage,
            width: 50,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 50, height: 70),
          ),
        ),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(item is AnimeEntity ? 'Anime • ${item.totalEpisodes} eps' : 'Manga'),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: AppTheme.accent,
          onPressed: () => _addToLibrary(context, item),
        ),
      ),
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
