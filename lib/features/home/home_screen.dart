import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/features/details/widgets/content_preview_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final animeListAsync = ref.watch(libraryAnimeProvider);
    final mangaListAsync = ref.watch(libraryMangaProvider);

    final hasLibraryContent = (animeListAsync.value?.isNotEmpty ?? false) || 
                             (mangaListAsync.value?.isNotEmpty ?? false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              
              if (hasLibraryContent) ...[
                // Continue Watching (Anime)
                const GTSectionHeader(title: 'Continue Watching'),
                animeListAsync.when(
                  data: (list) {
                    final active = list.where((a) => a.currentEpisode < a.totalEpisodes).toList();
                    if (active.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: active.length,
                        itemBuilder: (context, index) => _buildProgressCard(context, ref, active[index]),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                
                const SizedBox(height: 24),
                
                // Continue Reading (Manga)
                const GTSectionHeader(title: 'Continue Reading'),
                mangaListAsync.when(
                  data: (list) {
                    final active = list.where((m) => m.currentChapter < m.totalChapters || m.totalChapters == 0).toList();
                    if (active.isEmpty) return const SizedBox.shrink();
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: active.length,
                        itemBuilder: (context, index) => _buildProgressCard(context, ref, active[index]),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ] else ...[
                const GTSectionHeader(title: 'Discover Trending'),
                const SizedBox(height: 16),
                _buildTrendingGrid(context, ref),
              ],

              const SizedBox(height: 32),
              const GTSectionHeader(title: 'Daily Insights'),
              sessionsAsync.when(
                data: (sessions) {
                  final totalMins = sessions.isEmpty ? 0 : sessions.fold<int>(0, (sum, s) => sum + s.totalMinutes);
                  return GTStatCard(
                    title: 'Total Consumption Today',
                    value: '$totalMins Minutes',
                    icon: Icons.auto_graph,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingGrid(BuildContext context, WidgetRef ref) {
    final trendingAnime = ref.watch(trendingAnimeProvider);
    
    return trendingAnime.when(
      data: (list) => SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _showPreview(context, item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.coverImage,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppTheme.elevated),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME BACK',
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          'Gooner 1',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCTA(BuildContext context, WidgetRef ref) {
    final animeList = ref.watch(libraryAnimeProvider).value ?? [];
    final mangaList = ref.watch(libraryMangaProvider).value ?? [];
    
    if (animeList.isNotEmpty || mangaList.isNotEmpty) return const SizedBox.shrink();

    return GTEmptyState(
      icon: Icons.search,
      title: 'Nothing showing yet',
      description: 'Search and add content to start tracking your progress',
      buttonLabel: 'FIND CONTENT',
      onButtonPressed: () => context.go('/search'),
    );
  }

  Widget _buildProgressCard(BuildContext context, WidgetRef ref, TrackableContent item) {
    final isAnime = item is AnimeEntity;
    final progress = item.totalProgress > 0 
      ? (item.currentProgress / item.totalProgress)
      : 0.0;
    
    final progressText = isAnime 
      ? 'Ep ${item.currentProgress} / ${item.totalProgress}'
      : 'Ch ${item.currentProgress} / ${item.totalProgress > 0 ? item.totalProgress : '?'}';

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => context.push('/content/${item.id}/${isAnime ? 'anime' : 'manga'}'),
        child: GTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.coverImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.image)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0), 
                color: isAnime ? AppTheme.accent : Colors.green,
                backgroundColor: Colors.white10,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(progressText, style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add_circle, color: isAnime ? AppTheme.accent : Colors.green, size: 20),
                    onPressed: () {
                      if (isAnime) {
                        ref.read(trackerNotifierProvider.notifier).logAnimeEpisode(item as AnimeEntity, 24);
                      } else {
                        ref.read(trackerNotifierProvider.notifier).logMangaChapter(item as MangaEntity, 15);
                      }
                      ref.invalidate(libraryAnimeProvider);
                      ref.invalidate(libraryMangaProvider);
                      ref.invalidate(recentSessionsProvider);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
