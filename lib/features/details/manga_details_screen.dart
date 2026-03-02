import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';
import 'package:goon_tracker/app/providers.dart';

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
                  Text(
                    '${manga.currentChapter} / ${manga.totalChapters} Chapters',
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 24),
                  _buildStatusDropdown(context, ref),
                  const SizedBox(height: 16),
                  _buildRatingSelector(context, ref),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ref.read(trackerNotifierProvider.notifier).logMangaChapter(manga, 15),
                      child: const Text('LOG CHAPTER (15m)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
