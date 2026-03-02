import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MangaDetailScreen extends ConsumerWidget {
  final MangaEntity manga;

  const MangaDetailScreen({super.key, required this.manga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                manga.coverImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(manga.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (manga.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: manga.genres.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(g, style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                      )).toList(),
                    ),
                  const SizedBox(height: 24),
                  if (manga.description != null) ...[
                    const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(
                      manga.description!,
                      style: TextStyle(color: AppTheme.primaryText.withOpacity(0.8), height: 1.5),
                    ),
                    const SizedBox(height: 32),
                  ],
                  _buildProgressSection(context, ref),
                  const SizedBox(height: 32),
                  _buildStatusDropdown(context, ref),
                  const SizedBox(height: 16),
                  _buildRatingSelector(context, ref),
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
    final progress = manga.totalChapters > 0 ? manga.currentChapter / manga.totalChapters : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('YOUR PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.2)),
            Text('${manga.currentChapter} / ${manga.totalChapters > 0 ? manga.totalChapters : '??'}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('STATION LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText)),
                  const SizedBox(height: 4),
                  Text('Estimated: ${manga.currentChapter * 15}m total spent', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(trackerNotifierProvider.notifier).logMangaChapter(manga, 15);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged 1 Chapter (+15m)'), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('LOG CHAPTER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          items: MangaStatus.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              ref.read(mangaRepositoryProvider).saveManga(manga.copyWith(status: newStatus));
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
            onPressed: () {
              ref.read(mangaRepositoryProvider).saveManga(manga.copyWith(rating: starValue.toDouble()));
            },
          );
        }),
      ],
    );
  }
}
