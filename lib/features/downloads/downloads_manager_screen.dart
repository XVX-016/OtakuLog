import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/features/downloads/download_queue_notifier.dart';
import 'package:otakulog/features/reader/manga_reader_notifier.dart';

class DownloadsManagerScreen extends ConsumerWidget {
  const DownloadsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadedChaptersProvider);
    final totalBytesAsync = ref.watch(totalDownloadedBytesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DOWNLOADS')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offline storage used',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalBytesAsync.when(
                      data: formatBytes,
                      loading: () => 'Calculating...',
                      error: (_, __) => 'Unavailable',
                    ),
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Downloaded chapters',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: downloadsAsync.when(
                data: (downloads) {
                  if (downloads.isEmpty) {
                    return const Center(
                      child: Text(
                        'No offline chapters yet.',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: downloads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = downloads[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final manga = await ref.read(mangaByIdProvider(item.mangaId).future);
                          if (!context.mounted) return;
                          if (manga == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This manga is no longer in your library.'),
                              ),
                            );
                            return;
                          }

                          context.push(
                            '/reader/manga',
                            extra: MangaReaderArgs(
                              manga: manga,
                              mangaDexId: item.mangaDexId,
                              initialChapterId: item.chapterId,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.offline_pin, color: AppTheme.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item.chapterLabel?.trim().isNotEmpty ?? false)
                                          ? item.chapterLabel!.trim()
                                          : item.chapterId,
                                      style: const TextStyle(
                                        color: AppTheme.primaryText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.mangaTitle?.trim().isNotEmpty ?? false)
                                      Text(
                                        item.mangaTitle!.trim(),
                                        style: const TextStyle(
                                            color: AppTheme.secondaryText),
                                      ),
                                    if (item.mangaTitle?.trim().isNotEmpty ?? false)
                                      const SizedBox(height: 4),
                                    Text(
                                      '${(item.chapterTitle?.trim().isNotEmpty ?? false) ? '${item.chapterTitle!.trim()} - ' : ''}${item.totalPages} pages - ${formatBytes(item.totalBytes)}',
                                      style:
                                          const TextStyle(color: AppTheme.secondaryText),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy - h:mm a')
                                          .format(item.downloadedAt),
                                      style:
                                          const TextStyle(color: AppTheme.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(downloadQueueNotifierProvider.notifier)
                                      .deleteDownloadedChapter(item.chapterId);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                error: (_, __) => const Center(
                  child: Text(
                    'Could not load downloads.',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    final fixed = size >= 100 ? 0 : 1;
    return '${size.toStringAsFixed(fixed)} ${units[unitIndex]}';
  }
}
