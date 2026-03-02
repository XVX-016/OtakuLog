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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:goon_tracker/domain/services/stats_service.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';


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
              _buildHeader(context, ref),
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
                _buildEmptyStateSection(
                  context, 
                  'Your Station is Empty', 
                  Icons.auto_awesome_motion, 
                  'Discover trending series and start building your ultimate library today.',
                ),
                const SizedBox(height: 32),
                const GTSectionHeader(title: 'TRENDING NOW'),
                const SizedBox(height: 16),
                _buildTrendingGrid(context, ref),
              ],

              const SizedBox(height: 32),
              const GTSectionHeader(title: 'Daily Insights'),
              sessionsAsync.when(
                data: (sessions) {
                  final totalMins = sessions.isEmpty ? 0 : sessions.fold<int>(0, (sum, s) => sum + s.totalMinutes);
                  final statsService = StatsService();
                  final avgManga = statsService.calculateAverageMinutesPerUnit(sessions, SessionContentType.manga);
                  
                  return Column(
                    children: [
                      GTStatCard(
                        title: 'Total Consumption Today',
                        value: '$totalMins Minutes',
                        icon: Icons.auto_graph,
                      ),
                      if (avgManga > 0) ...[
                        const SizedBox(height: 12),
                        GTStatCard(
                          title: 'Average Chapter Speed',
                          value: '${avgManga.toStringAsFixed(1)} min/ch',
                          icon: Icons.speed,
                        ),
                      ],
                    ],
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
                        child: CachedNetworkImage(
                          imageUrl: item.coverImage,
                          width: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: AppTheme.elevated,
                            highlightColor: AppTheme.surface,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.elevated,
                            child: const Icon(Icons.broken_image, color: AppTheme.secondaryText),
                          ),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        userAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                user?.name.toUpperCase() ?? 'COMMANDER',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
        if (userAsync.value == null)
          TextButton.icon(
            onPressed: () => _showCreateProfile(context, ref),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('SETUP'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
          )
        else 
          const CircleAvatar(
            backgroundColor: AppTheme.elevated,
            child: Icon(Icons.person, color: AppTheme.secondaryText),
          ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  void _showCreateProfile(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME COMMANDER',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            const Text(
              'Initialize your station profile to begin tracking.',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Enter callsign...',
                filled: true,
                fillColor: AppTheme.elevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final user = UserEntity(
                      name: nameController.text,
                      defaultSearchType: 'anime',
                      defaultContentRating: 'safe',
                    );
                    final success = await ref.read(userRepositoryProvider).saveUser(user);
                    if (success) {
                      ref.invalidate(currentUserProvider);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('INITIALIZE PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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
                  child: CachedNetworkImage(
                    imageUrl: item.coverImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.white10,
                      highlightColor: Colors.white24,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported),
                    ),
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
