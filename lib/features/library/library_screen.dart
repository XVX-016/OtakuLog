import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/features/library/widgets/item_actions_sheet.dart';
import 'package:otakulog/features/tracker/tracker_feedback.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';
import 'package:otakulog/features/tracker/widgets/log_to_target_sheet.dart';

enum LibraryFilter { all, anime, manga }

enum LibrarySortOption { recentlyUpdated, recentlyLogged, titleAZ, titleZA, progressAsc, progressDesc, rating }

final libraryFilterProvider = StateProvider<LibraryFilter>((ref) => LibraryFilter.all);
final librarySortProvider = StateProvider<LibrarySortOption>((ref) => LibrarySortOption.recentlyUpdated);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combinedAsync = ref.watch(combinedLibraryProvider);
    final filter = ref.watch(libraryFilterProvider);
    final sort = ref.watch(librarySortProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final trackerState = ref.watch(trackerNotifierProvider);
    final latestSessionByContent = ref.watch(latestSessionByContentProvider).valueOrNull ?? const <String, DateTime>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIBRARY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortSheet(context, ref, sort),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedControl(ref, filter),
          Expanded(
            child: combinedAsync.when(
              data: (list) {
                final filteredList = _applySort(_applyFilter(list, filter), sort, latestSessionByContent);

                if (filteredList.isEmpty) {
                  return GTEmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'Your Library is Empty',
                    description: 'Search and add some content to track your progress.',
                    buttonLabel: 'GO TO SEARCH',
                    onButtonPressed: () => context.go('/search'),
                  );
                }

                final inProgress = filteredList.where(_isInProgress).toList();
                final completed = filteredList.where((item) => !_isInProgress(item)).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (inProgress.isNotEmpty) ...[
                      const GTSectionHeader(title: 'In Progress'),
                      ...inProgress.map((item) => _buildLibraryCard(
                            context,
                            ref,
                            item,
                            user,
                            trackerState.isBusy(item.id),
                          )),
                    ],
                    if (completed.isNotEmpty) ...[
                      const GTSectionHeader(title: 'Completed'),
                      ...completed.map((item) => _buildLibraryCard(
                            context,
                            ref,
                            item,
                            user,
                            trackerState.isBusy(item.id),
                          )),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<TrackableContent> _applyFilter(List<TrackableContent> items, LibraryFilter filter) {
    return items.where((item) {
      if (filter == LibraryFilter.anime) return item is AnimeEntity;
      if (filter == LibraryFilter.manga) return item is MangaEntity;
      return true;
    }).toList();
  }

  List<TrackableContent> _applySort(
    List<TrackableContent> items,
    LibrarySortOption sort,
    Map<String, DateTime> latestSessionByContent,
  ) {
    final sorted = [...items];

    switch (sort) {
      case LibrarySortOption.recentlyUpdated:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case LibrarySortOption.recentlyLogged:
        sorted.sort((a, b) {
          final aDate = latestSessionByContent[a.id] ?? a.updatedAt;
          final bDate = latestSessionByContent[b.id] ?? b.updatedAt;
          return bDate.compareTo(aDate);
        });
        break;
      case LibrarySortOption.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case LibrarySortOption.titleZA:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case LibrarySortOption.progressAsc:
        sorted.sort((a, b) => _progressPercent(a).compareTo(_progressPercent(b)));
        break;
      case LibrarySortOption.progressDesc:
        sorted.sort((a, b) => _progressPercent(b).compareTo(_progressPercent(a)));
        break;
      case LibrarySortOption.rating:
        sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }

    return sorted;
  }

  double _progressPercent(TrackableContent item) {
    if (item.totalProgress <= 0) return 0;
    return item.currentProgress / item.totalProgress;
  }

  Widget _buildSegmentedControl(WidgetRef ref, LibraryFilter currentFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<LibraryFilter>(
          segments: const [
            ButtonSegment(value: LibraryFilter.all, label: Text('All')),
            ButtonSegment(value: LibraryFilter.anime, label: Text('Anime')),
            ButtonSegment(value: LibraryFilter.manga, label: Text('Manga')),
          ],
          selected: {currentFilter},
          onSelectionChanged: (selection) {
            ref.read(libraryFilterProvider.notifier).state = selection.first;
          },
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref, LibrarySortOption currentSort) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sort by',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText),
              ),
            ),
            for (final option in LibrarySortOption.values)
              ListTile(
                title: Text(_sortLabel(option)),
                trailing: currentSort == option ? const Icon(Icons.check, color: AppTheme.accent) : null,
                onTap: () {
                  ref.read(librarySortProvider.notifier).state = option;
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _sortLabel(LibrarySortOption option) {
    switch (option) {
      case LibrarySortOption.recentlyUpdated:
        return 'Recently Updated';
      case LibrarySortOption.recentlyLogged:
        return 'Recently Logged';
      case LibrarySortOption.titleAZ:
        return 'Title A - Z';
      case LibrarySortOption.titleZA:
        return 'Title Z - A';
      case LibrarySortOption.progressAsc:
        return 'Least Progress';
      case LibrarySortOption.progressDesc:
        return 'Most Progress';
      case LibrarySortOption.rating:
        return 'Highest Rated';
    }
  }

  Widget _buildLibraryCard(
    BuildContext context,
    WidgetRef ref,
    TrackableContent item,
    UserEntity? user,
    bool isBusy,
  ) {
    final anime = item is AnimeEntity ? item : null;
    final manga = item is MangaEntity ? item : null;
    final isAnime = anime != null;
    final canLogMore = item.totalProgress <= 0 || item.currentProgress < item.totalProgress;
    final total = item.totalProgress;
    final progressText = isAnime
        ? 'Ep ${item.currentProgress} / ${total > 0 ? total : '?'}'
        : 'Ch ${item.currentProgress} / ${total > 0 ? total : '?'}';
    final statusText = isAnime ? anime.status.name : manga!.status.name;
    final progress = total > 0 ? item.currentProgress / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDetails(context, item),
        onLongPress: () => _showItemActions(context, ref, item, user),
        child: GTCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GTCoverImage(
                imageUrl: user?.blurCoverInPublic == true ? '' : item.coverImage,
                title: item.title,
                width: 86,
                height: 124,
                badge: isAnime ? 'ANIME' : 'MANGA',
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progressText,
                      style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    GTProgressBar(progress: progress, height: 6),
                    const SizedBox(height: 8),
                    Text(
                      statusText.toUpperCase(),
                      style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: isBusy || !canLogMore ? null : () => _quickLog(context, ref, item, user),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: isAnime ? AppTheme.accent : Colors.green[800],
                  ),
                  child: Text(
                    isBusy
                        ? '...'
                        : isAnime
                            ? '+1 Ep'
                            : '+1 Ch',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickLog(
    BuildContext context,
    WidgetRef ref,
    TrackableContent item,
    UserEntity? user,
  ) async {
    try {
      await ref.read(localAnalyticsServiceProvider).track('quick_log');
      ref.invalidate(analyticsSnapshotProvider);
      final result = item is AnimeEntity
          ? await ref
              .read(trackerNotifierProvider.notifier)
              .logAnimeEpisode(item, user: user)
          : await ref
              .read(trackerNotifierProvider.notifier)
              .logMangaChapter(item as MangaEntity, user: user);
      if (!context.mounted) return;
      if (result != null) {
        await showTrackerFeedback(context, ref, result);
      } else {
        await showTrackerMessage(
          context,
          message: item is AnimeEntity
              ? 'Unable to log episode'
              : 'Unable to log chapter',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      await showTrackerMessage(
        context,
        message: item is AnimeEntity
            ? 'Unable to log episode'
            : 'Unable to log chapter',
      );
    }
  }

  Future<void> _showItemActions(
    BuildContext context,
    WidgetRef ref,
    TrackableContent item,
    UserEntity? user,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ItemActionsSheet(
        item: item,
        onQuickLog: () async {
          Navigator.pop(sheetContext);
          await _quickLog(context, ref, item, user);
        },
        onLogToTarget: () async {
          Navigator.pop(sheetContext);
          await _showLogToTarget(context, ref, item, user);
        },
        onMarkCompleted: () async {
          Navigator.pop(sheetContext);
          final result = await ref.read(trackerNotifierProvider.notifier).markCompleted(item, user: user);
          if (context.mounted) {
            await showTrackerFeedback(context, ref, result);
          }
        },
        onUpdateRating: () async {
          Navigator.pop(sheetContext);
          await _showRatingDialog(context, ref, item);
        },
        onRemove: () async {
          Navigator.pop(sheetContext);
          final result = await ref.read(trackerNotifierProvider.notifier).removeFromLibrary(item);
          if (context.mounted) {
            await showTrackerFeedback(context, ref, result);
          }
        },
      ),
    );
  }

  Future<void> _showLogToTarget(
    BuildContext context,
    WidgetRef ref,
    TrackableContent item,
    UserEntity? user,
  ) async {
    if (item.totalProgress > 0 && item.currentProgress >= item.totalProgress) {
      return;
    }

    final target = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogToTargetSheet(
        content: item,
        minutesPerUnit: item is AnimeEntity ? (user?.defaultAnimeWatchTime ?? 24) : (user?.avgChapterMinutes ?? 15),
      ),
    );

    if (target == null) return;

    await ref.read(localAnalyticsServiceProvider).track('log_to_target');
    ref.invalidate(analyticsSnapshotProvider);
    final result = item is AnimeEntity
        ? await ref.read(trackerNotifierProvider.notifier).logAnimeToEpisode(item, target, user: user)
        : await ref.read(trackerNotifierProvider.notifier).logMangaToChapter(item as MangaEntity, target, user: user);
    if (context.mounted) {
      await showTrackerFeedback(context, ref, result);
    }
  }

  Future<void> _showRatingDialog(
    BuildContext context,
    WidgetRef ref,
    TrackableContent item,
  ) async {
    var selectedRating = item.rating ?? 0;
    final rating = await showDialog<double>(
      context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              'Update Rating',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => selectedRating = star.toDouble()),
                    icon: Icon(
                      selectedRating >= star ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              );
            },
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, selectedRating),
                child: const Text('Save'),
              ),
          ],
        );
      },
    );

    if (rating == null) return;
    final result = await ref.read(trackerNotifierProvider.notifier).updateRating(item, rating);
    if (context.mounted) {
      await showTrackerFeedback(context, ref, result);
    }
  }

  void _openDetails(BuildContext context, TrackableContent item) {
    final type = item is AnimeEntity ? 'anime' : 'manga';
    context.push('/content/${item.id}/$type');
  }

  bool _isInProgress(TrackableContent item) {
    if (item is AnimeEntity) return item.status != AnimeStatus.completed;
    if (item is MangaEntity) return item.status != MangaStatus.completed;
    return false;
  }
}
