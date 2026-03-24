import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/utils/progress_utils.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/downloads/download_queue_notifier.dart';
import 'package:otakulog/features/reader/manga_reader_notifier.dart';
import 'package:otakulog/features/tracker/tracker_feedback.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';

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
                        imageUrl: manga.coverImage,
                        title: manga.title,
                        badge: 'MANGA',
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final releaseCap = ref
        .watch(
          mangaReleaseCapForMangaProvider(
            MangaReleaseCapLookup(
              mangaId: manga.id,
              coverImageUrl: manga.coverImage,
              title: manga.title,
            ),
          ),
        )
        .valueOrNull;
    final maxAllowedProgress =
        getMaxAllowedProgress(manga, releaseCap: releaseCap);
    final isCapped =
        maxAllowedProgress != null && manga.currentChapter >= maxAllowedProgress;
    final unitMinutes = user?.avgChapterMinutes ?? 15;
    final totalForDisplay = manga.totalChapters > 0
        ? manga.totalChapters
        : maxAllowedProgress;
    final progress = totalForDisplay != null && totalForDisplay > 0
        ? manga.currentChapter / totalForDisplay
        : 0.0;
    final displayTotal = totalForDisplay?.toString() ?? '?';
    final estimatedMinutes = manga.currentChapter * unitMinutes;

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
              '${manga.currentChapter} / $displayTotal',
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
        const SizedBox(height: 10),
        Text(
          'Estimated total spent: ${estimatedMinutes}m',
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 12,
          ),
        ),
        if (manga.totalChapters <= 0 && maxAllowedProgress != null) ...[
          const SizedBox(height: 6),
          Text(
            'Released so far: $maxAllowedProgress chapters',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openReader(context, ref),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('READ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isCapped
                    ? null
                    : () async {
                        try {
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
                          if (!context.mounted) return;
                          if (result != null) {
                            await showTrackerFeedback(context, ref, result);
                          } else {
                            await showTrackerMessage(
                              context,
                              message: 'Unable to log chapter',
                            );
                          }
                        } catch (_) {
                          if (!context.mounted) return;
                          await showTrackerMessage(
                            context,
                            message: 'Unable to log chapter',
                          );
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('LOG CHAPTER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (manga.totalChapters <= 0 && maxAllowedProgress != null) ...[
          const SizedBox(height: 8),
          Text(
            'Only $maxAllowedProgress chapters released so far.',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _openReader(BuildContext context, WidgetRef ref) async {
    final service = ref.read(mangadexServiceProvider);
    final readableMangaId = service.resolveMangaDexMangaId(
      manga.id,
      coverImageUrl: manga.coverImage,
    );

    final selected = await showModalBottomSheet<MangaDexChapter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ChapterSelectorSheet(
          manga: manga,
          mangaDexId: readableMangaId,
          service: service,
        );
      },
    );

    if (selected == null || !context.mounted) return;
    context.push(
      '/reader/manga',
      extra: MangaReaderArgs(
        manga: manga,
        mangaDexId: readableMangaId,
        initialChapterId: selected.id,
      ),
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
        child: DropdownButton<MangaStatus>(
            isDense: false,
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

class _ChapterSelectorSheet extends ConsumerStatefulWidget {
  final MangaEntity manga;
  final String? mangaDexId;
  final MangadexService service;

  const _ChapterSelectorSheet({
    required this.manga,
    required this.mangaDexId,
    required this.service,
  });

  @override
  ConsumerState<_ChapterSelectorSheet> createState() =>
      _ChapterSelectorSheetState();
}

class _ChapterSelectorSheetState extends ConsumerState<_ChapterSelectorSheet>
    with WidgetsBindingObserver {
  late Future<List<MangaDexChapter>> _chapterFeedFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chapterFeedFuture = _loadChapterFeed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _retryChapterFeed();
  }

  Future<List<MangaDexChapter>> _loadChapterFeed() {
    return widget.service.fetchChapterFeed(
      widget.mangaDexId ?? widget.manga.id,
      coverImageUrl: widget.manga.coverImage,
      title: widget.manga.title,
    );
  }

  void _retryChapterFeed() {
    if (!mounted) return;
    setState(() {
      _chapterFeedFuture = _loadChapterFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    final downloadsAsync = ref.watch(downloadedChaptersProvider);
    final queueState = ref.watch(downloadQueueNotifierProvider);
    final normalizedTitle = widget.manga.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final downloadedRecords = downloadsAsync.valueOrNull
            ?.where(
              (item) =>
                  item.mangaId == widget.manga.id ||
                  (widget.mangaDexId != null &&
                      item.mangaDexId == widget.mangaDexId) ||
                  (normalizedTitle.isNotEmpty &&
                      (item.mangaTitle ?? '')
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim() ==
                          normalizedTitle),
            )
            .toList() ??
        const [];
    final offlineChapters = downloadedRecords
        .map(
          (item) => MangaDexChapter(
            id: item.chapterId,
            title: (item.chapterTitle?.trim().isNotEmpty ?? false)
                ? item.chapterTitle!.trim()
                : 'Downloaded for offline reading',
            chapterLabel: (item.chapterLabel?.trim().isNotEmpty ?? false)
                ? item.chapterLabel!.trim()
                : 'Offline chapter',
            chapterNumber: double.infinity,
            chapterText: '',
            volumeText: '',
            pageCount: item.totalPages,
          ),
        )
        .toList();

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SizedBox(
          height: maxHeight,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a chapter',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.manga.title,
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<MangaDexChapter>>(
                future: _chapterFeedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    if (offlineChapters.isNotEmpty) {
                      return _OfflineChapterList(
                        chapters: offlineChapters,
                        downloadedIds: downloadedRecords
                            .map((item) => item.chapterId)
                            .toSet(),
                        queueState: queueState,
                        mangaId: widget.manga.id,
                      );
                    }
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppTheme.accent),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final message = 'No network or MangaDex is blocked right now.';
                    if (offlineChapters.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$message Showing downloaded chapters instead.',
                            style: const TextStyle(color: AppTheme.secondaryText),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _retryChapterFeed,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _OfflineChapterList(
                              chapters: offlineChapters,
                              downloadedIds: downloadedRecords
                                  .map((item) => item.chapterId)
                                  .toSet(),
                              queueState: queueState,
                              mangaId: widget.manga.id,
                            ),
                          ),
                        ],
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No network or MangaDex is blocked right now.',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _retryChapterFeed,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final chapters = snapshot.data ?? const [];
                  if (chapters.isEmpty) {
                    if (offlineChapters.isNotEmpty) {
                      return _OfflineChapterList(
                        chapters: offlineChapters,
                        downloadedIds: downloadedRecords
                            .map((item) => item.chapterId)
                            .toSet(),
                        queueState: queueState,
                        mangaId: widget.manga.id,
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No readable English chapters found.',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                    );
                  }

                  final downloadedIds =
                      downloadsAsync.valueOrNull?.map((item) => item.chapterId).toSet() ??
                          const <String>{};

                  return ListView.separated(
                    itemCount: chapters.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      final secondaryText = _chapterSecondaryText(chapter);
                      final progress = queueState.progressFor(chapter.id);
                      final isDownloaded = downloadedIds.contains(chapter.id);
                      return ListTile(
                        onTap: () => Navigator.pop(context, chapter),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _chapterPrimaryLabel(chapter),
                          style: const TextStyle(color: AppTheme.primaryText),
                        ),
                        subtitle: secondaryText == null
                            ? null
                            : Text(
                                secondaryText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.secondaryText),
                              ),
                        leading: _ChapterDownloadButton(
                          chapter: chapter,
                          mangaId: widget.manga.id,
                          mangaDexId: widget.mangaDexId,
                          mangaTitle: widget.manga.title,
                          progress: progress,
                          isDownloaded: isDownloaded,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isDownloaded)
                              const Icon(
                                Icons.offline_pin,
                                color: AppTheme.accent,
                                size: 18,
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

class _OfflineChapterList extends StatelessWidget {
  final List<MangaDexChapter> chapters;
  final Set<String> downloadedIds;
  final DownloadQueueState queueState;
  final String mangaId;

  const _OfflineChapterList({
    required this.chapters,
    required this.downloadedIds,
    required this.queueState,
    required this.mangaId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: chapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final secondaryText = _chapterSecondaryText(chapter);
        final progress = queueState.progressFor(chapter.id);
        final isDownloaded = downloadedIds.contains(chapter.id);
        return ListTile(
          onTap: () => Navigator.pop(context, chapter),
          contentPadding: EdgeInsets.zero,
          title: Text(
            _chapterPrimaryLabel(chapter),
            style: const TextStyle(color: AppTheme.primaryText),
          ),
          subtitle: secondaryText == null
              ? null
              : Text(
                  secondaryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.secondaryText),
                ),
          leading: _ChapterDownloadButton(
            chapter: chapter,
            mangaId: mangaId,
            progress: progress,
            isDownloaded: isDownloaded,
          ),
          trailing: const Icon(
            Icons.offline_pin,
            color: AppTheme.accent,
            size: 18,
          ),
        );
      },
    );
  }
}

class _ChapterDownloadButton extends ConsumerWidget {
  final MangaDexChapter chapter;
  final String mangaId;
  final String? mangaDexId;
  final String? mangaTitle;
  final ChapterDownloadProgress progress;
  final bool isDownloaded;

  const _ChapterDownloadButton({
    required this.chapter,
    required this.mangaId,
    this.mangaDexId,
    this.mangaTitle,
    required this.progress,
    required this.isDownloaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = switch (progress.status) {
      DownloadStatus.downloading => null,
      DownloadStatus.queued => Icons.schedule,
      DownloadStatus.done => Icons.offline_pin,
      DownloadStatus.error => Icons.error_outline,
      DownloadStatus.idle => isDownloaded ? Icons.offline_pin : Icons.download_outlined,
    };

    return IconButton(
      tooltip: isDownloaded ? 'Downloaded' : 'Download chapter',
      onPressed: isDownloaded
          ? null
          : () {
              ref.read(downloadQueueNotifierProvider.notifier).enqueue(
                    mangaId: mangaId,
                    mangaDexId: mangaDexId,
                    mangaTitle: mangaTitle,
                    chapter: chapter,
                  );
            },
      icon: progress.status == DownloadStatus.downloading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: progress.progress == 0 ? null : progress.progress,
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            )
          : Icon(
              icon,
              color: isDownloaded || progress.status == DownloadStatus.done
                  ? AppTheme.accent
                  : (progress.status == DownloadStatus.error
                      ? Colors.redAccent
                      : AppTheme.primaryText),
            ),
    );
  }
}

String? _chapterSecondaryText(MangaDexChapter chapter) {
  final title = chapter.title.trim();
  if (title.isEmpty) return null;
  final normalizedTitle = _normalizeChapterText(title);
  final normalizedLabel = _normalizeChapterText(_chapterPrimaryLabel(chapter));
  if (normalizedTitle.isEmpty || normalizedTitle == normalizedLabel) {
    return null;
  }
  return title;
}

String _chapterPrimaryLabel(MangaDexChapter chapter) {
  if (chapter.chapterText.trim().isNotEmpty) {
    return 'Ch. ${chapter.chapterText.trim()}';
  }
  return chapter.chapterLabel;
}

String _normalizeChapterText(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
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
