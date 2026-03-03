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
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/services/stats_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final trackingItems = ref.watch(combinedLibraryProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userAsync.when(
                data: (user) {
                  if (user == null) return _buildSetupFlow(context, ref);
                  return _buildHeader(user);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              const GTSectionHeader(title: 'YOUR STATION'),
              const SizedBox(height: 16),
              trackingItems.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _buildEmptyStateSection(
                      context, 
                      'Your Station is Empty', 
                      Icons.auto_awesome_motion, 
                      'Discover trending series and start building your ultimate library today.',
                    );
                  }
                  
                  final activeItems = items.take(4).toList();
                  return Column(
                    children: activeItems.map((item) => _buildProgressCard(context, ref, item)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: 32),
              const GTSectionHeader(title: 'TRENDING NOW'),
              const SizedBox(height: 16),
              _buildTrendingGrid(context, ref),

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

  Widget _buildHeader(UserEntity user) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WELCOME BACK,',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        GTCircularAvatar(path: user.avatarPath, radius: 28),
      ],
    );
  }

  Widget _buildSetupFlow(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STATION UNAUTHORIZED',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
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
                  id: 'local_user',
                  name: nameController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await ref.read(userRepositoryProvider).saveUser(user);
                ref.invalidate(currentUserProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('INITIALIZE PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateSection(BuildContext context, String title, IconData icon, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 48),
          const SizedBox(height: 24),
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.5),
          ),
        ],
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
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: item.coverImage,
                          width: 150,
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildProgressCard(BuildContext context, WidgetRef ref, TrackableContent item) {
    final isAnime = item is AnimeEntity;
    final progress = item.totalProgress > 0 ? item.currentProgress / item.totalProgress : 0.0;
    
    return InkWell(
      onTap: () => _showPreview(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.coverImage,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(isAnime ? AppTheme.accent : Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.currentProgress}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  isAnime ? 'EPISODES' : 'CHAPTERS',
                  style: const TextStyle(fontSize: 9, color: AppTheme.secondaryText),
                ),
              ],
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
}
