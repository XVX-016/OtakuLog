import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

enum LibraryFilter { all, anime, manga }

final libraryFilterProvider = StateProvider<LibraryFilter>((ref) => LibraryFilter.all);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combinedAsync = ref.watch(combinedLibraryProvider);
    final filter = ref.watch(libraryFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LIBRARY')),
      body: Column(
        children: [
          _buildSegmentedControl(context, ref, filter),
          Expanded(
            child: combinedAsync.when(
              data: (list) {
                // Filter the list
                final filteredList = list.where((item) {
                  if (filter == LibraryFilter.anime) return item is AnimeEntity;
                  if (filter == LibraryFilter.manga) return item is MangaEntity;
                  return true;
                }).toList();

                if (filteredList.isEmpty) {
                  return GTEmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'Your Library is Empty',
                    description: 'Search and add some content to track your progress!',
                    buttonLabel: 'GO TO SEARCH',
                    onButtonPressed: () => ref.read(libraryFilterProvider.notifier).state = LibraryFilter.all, // Simple reset or just leave as is since Search is a tab
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _buildLibraryCard(context, ref, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, WidgetRef ref, LibraryFilter currentFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<LibraryFilter>(
          segments: const [
            ButtonSegment(value: LibraryFilter.all, label: Text('All')),
            ButtonSegment(value: LibraryFilter.anime, label: Text('Anime')),
            ButtonSegment(value: LibraryFilter.manga, label: Text('Manga')),
          ],
          selected: {currentFilter},
          onSelectionChanged: (Set<LibraryFilter> newSelection) {
            ref.read(libraryFilterProvider.notifier).state = newSelection.first;
          },
        ),
      ),
    );
  }

  Widget _buildLibraryCard(BuildContext context, WidgetRef ref, TrackableContent item) {
    final isAnime = item is AnimeEntity;
    
    String progressText = '';
    String statusText = '';
    
    if (isAnime) {
      final anime = item as AnimeEntity;
      progressText = 'Ep ${anime.currentEpisode} / ${anime.totalEpisodes > 0 ? anime.totalEpisodes : '?'}';
      statusText = anime.status.name.toUpperCase();
    } else if (item is MangaEntity) {
      final manga = item as MangaEntity;
      progressText = 'Ch ${manga.currentChapter} / ${manga.totalChapters > 0 ? manga.totalChapters : '?'}';
      statusText = manga.status.name.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final type = isAnime ? 'anime' : 'manga';
          context.push('/content/${item.id}/$type');
        },
        child: GTCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.coverImage.isNotEmpty ? item.coverImage : 'https://via.placeholder.com/150',
                  width: 70,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppTheme.elevated,
                    highlightColor: AppTheme.surface,
                    child: Container(color: Colors.white, width: 70, height: 100),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    width: 70,
                    height: 100,
                    child: const Icon(Icons.broken_image, color: AppTheme.secondaryText, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAnime ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAnime ? 'ANIME' : 'MANGA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAnime ? Colors.blue[200] : Colors.green[200],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(progressText, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                        Text(statusText, style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
