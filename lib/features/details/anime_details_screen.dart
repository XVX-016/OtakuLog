import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/utils/progress_utils.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/features/tracker/tracker_feedback.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';

class AnimeDetailScreen extends ConsumerWidget {
  final String itemId;
  final AnimeEntity? cachedAnime;

  const AnimeDetailScreen({
    super.key,
    required this.itemId,
    this.cachedAnime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cachedAnime != null) {
      return _AnimeDetailBody(itemId: itemId, anime: cachedAnime!);
    }

    final animeAsync = ref.watch(animeByIdProvider(itemId));
    return animeAsync.when(
      data: (anime) {
        if (anime == null) {
          return const _DetailNotFoundState(label: 'Anime not found');
        }
        return _AnimeDetailBody(itemId: itemId, anime: anime);
      },
      loading: () => const _DetailLoadingState(),
      error: (_, __) => const _DetailNotFoundState(label: 'Anime not found'),
    );
  }
}

class _AnimeDetailBody extends ConsumerWidget {
  final String itemId;
  final AnimeEntity anime;

  const _AnimeDetailBody({
    required this.itemId,
    required this.anime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 156,
                      height: 228,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: GTCoverImage(
                        imageUrl: anime.coverImage,
                        title: anime.title,
                        badge: 'ANIME',
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    anime.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (anime.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: anime.genres
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.elevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                g,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 24),
                    if (stripHtmlTags(anime.description).isNotEmpty) ...[
                      const Text(
                        'DESCRIPTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        stripHtmlTags(anime.description),
                        style: TextStyle(
                          color: AppTheme.primaryText.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  _buildProgressSection(context, ref),
                  const SizedBox(height: 32),
                  _buildStatusDropdown(context, ref),
                  const SizedBox(height: 16),
                  _buildRatingSelector(context, ref),
                  const SizedBox(height: 16),
                  _buildRemoveButton(context, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref) {
    final progress = anime.totalEpisodes > 0
        ? anime.currentEpisode / anime.totalEpisodes
        : 0.0;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final releaseCap = ref.watch(animeReleaseCapProvider(anime.id)).valueOrNull;
    final maxAllowedProgress =
        getMaxAllowedProgress(anime, releaseCap: releaseCap);
    final isCapped =
        maxAllowedProgress != null && anime.currentEpisode >= maxAllowedProgress;
    final unitMinutes = user?.defaultAnimeWatchTime ?? 24;
    final displayTotal = anime.totalEpisodes > 0
        ? anime.totalEpisodes.toString()
        : (maxAllowedProgress?.toString() ?? '?');
    final estimatedMinutes = anime.currentEpisode * unitMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'YOUR PROGRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryText,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              '${anime.currentEpisode} / $displayTotal',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.elevated,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Estimated total spent: ${estimatedMinutes}m',
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        if (anime.totalEpisodes <= 0 && maxAllowedProgress != null) ...[
          const SizedBox(height: 6),
          Text(
            'Released so far: $maxAllowedProgress episodes',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: isCapped
                  ? null
                  : () async {
                await ref
                    .read(localAnalyticsServiceProvider)
                    .track('quick_log');
                ref.invalidate(analyticsSnapshotProvider);
                final result = await ref
                    .read(trackerNotifierProvider.notifier)
                    .logAnimeEpisode(
                      anime,
                      user: user,
                    );
                if (context.mounted) {
                  await showTrackerFeedback(context, ref, result);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('LOG EPISODE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        if (anime.totalEpisodes <= 0 && maxAllowedProgress != null) ...[
          const SizedBox(height: 8),
          Text(
            'Only $maxAllowedProgress episodes released so far.',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusDropdown(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AnimeStatus>(
            isDense: false,
            value: anime.status,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            iconEnabledColor: AppTheme.primaryText,
            selectedItemBuilder: (context) {
              return AnimeStatus.values
                  .map(
                    (s) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        s.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
            items: AnimeStatus.values.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(
                  s.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          onChanged: (newStatus) async {
            if (newStatus != null) {
              final saved = await ref.read(animeRepositoryProvider).saveAnime(
                    anime.copyWith(
                      status: newStatus,
                      updatedAt: DateTime.now(),
                    ),
                  );
              if (saved) {
                ref.invalidate(libraryAnimeProvider);
                ref.invalidate(combinedLibraryProvider);
                ref.invalidate(animeByIdProvider(itemId));
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildRatingSelector(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text('Rating: ', style: TextStyle(color: AppTheme.secondaryText)),
        const Spacer(),
        ...List.generate(5, (index) {
          final starValue = index + 1;
          return IconButton(
            icon: Icon(
              (anime.rating ?? 0) >= starValue ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () async {
              final result =
                  await ref.read(trackerNotifierProvider.notifier).updateRating(
                        anime.copyWith(updatedAt: DateTime.now()),
                        starValue.toDouble(),
                      );
              if (context.mounted) {
                await showTrackerFeedback(context, ref, result);
              }
              ref.invalidate(animeByIdProvider(itemId));
            },
          );
        }),
      ],
    );
  }

  Widget _buildRemoveButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Remove from library?',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              content: Text(
                'This will remove ${anime.title} from your library.',
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    'REMOVE',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );

          if (confirmed != true || !context.mounted) return;

          final result = await ref
              .read(trackerNotifierProvider.notifier)
              .removeFromLibrary(anime);
          if (context.mounted) {
            await showTrackerFeedback(context, ref, result);
          }
          ref.invalidate(animeByIdProvider(itemId));
          if (context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        label: const Text(
          'REMOVE FROM LIBRARY',
          style: TextStyle(color: Colors.redAccent),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}

class _DetailNotFoundState extends StatelessWidget {
  final String label;

  const _DetailNotFoundState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryText),
        ),
      ),
    );
  }
}
