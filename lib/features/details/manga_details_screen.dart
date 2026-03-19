import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/utils/text_sanitizer.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/features/tracker/tracker_feedback.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';

class MangaDetailScreen extends ConsumerWidget {
  final String itemId;
  final MangaEntity? cachedManga;

  const MangaDetailScreen({
    super.key,
    required this.itemId,
    this.cachedManga,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cachedManga != null) {
      return _MangaDetailBody(itemId: itemId, manga: cachedManga!);
    }

    final mangaAsync = ref.watch(mangaByIdProvider(itemId));
    return mangaAsync.when(
      data: (manga) {
        if (manga == null) {
          return const _DetailNotFoundState(label: 'Manga not found');
        }
        return _MangaDetailBody(itemId: itemId, manga: manga);
      },
      loading: () => const _DetailLoadingState(),
      error: (_, __) => const _DetailNotFoundState(label: 'Manga not found'),
    );
  }
}

class _MangaDetailBody extends ConsumerWidget {
  final String itemId;
  final MangaEntity manga;

  const _MangaDetailBody({
    required this.itemId,
    required this.manga,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GTCoverImage(
                imageUrl: manga.coverImage,
                title: manga.title,
                fit: BoxFit.cover,
                badge: 'MANGA',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (manga.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: manga.genres
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
                    if (stripHtmlTags(manga.description).isNotEmpty) ...[
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
                        stripHtmlTags(manga.description),
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
    final progress = manga.totalChapters > 0
        ? manga.currentChapter / manga.totalChapters
        : 0.0;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final unitMinutes = user?.avgChapterMinutes ?? 15;

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
              '${manga.currentChapter} / ${manga.totalChapters > 0 ? manga.totalChapters : '??'}',
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
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATION LOG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated: ${manga.currentChapter * unitMinutes}m total spent',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(localAnalyticsServiceProvider)
                    .track('quick_log');
                ref.invalidate(analyticsSnapshotProvider);
                final result = await ref
                    .read(trackerNotifierProvider.notifier)
                    .logMangaChapter(
                      manga,
                      user: user,
                    );
                if (context.mounted) {
                  await showTrackerFeedback(context, ref, result);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('LOG CHAPTER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MangaStatus>(
            value: manga.status,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            iconEnabledColor: AppTheme.primaryText,
            selectedItemBuilder: (context) {
              return MangaStatus.values
                  .map(
                    (s) => Text(
                      s.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList();
            },
            items: MangaStatus.values.map((s) {
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
              final saved = await ref.read(mangaRepositoryProvider).saveManga(
                    manga.copyWith(
                      status: newStatus,
                      updatedAt: DateTime.now(),
                    ),
                  );
              if (saved) {
                ref.invalidate(libraryMangaProvider);
                ref.invalidate(combinedLibraryProvider);
                ref.invalidate(mangaByIdProvider(itemId));
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
              (manga.rating ?? 0) >= starValue ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () async {
              final result =
                  await ref.read(trackerNotifierProvider.notifier).updateRating(
                        manga.copyWith(updatedAt: DateTime.now()),
                        starValue.toDouble(),
                      );
              if (context.mounted) {
                await showTrackerFeedback(context, ref, result);
              }
              ref.invalidate(mangaByIdProvider(itemId));
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
                'This will remove ${manga.title} from your library.',
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
              .removeFromLibrary(manga);
          if (context.mounted) {
            await showTrackerFeedback(context, ref, result);
          }
          ref.invalidate(mangaByIdProvider(itemId));
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
