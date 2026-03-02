import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/app/providers.dart';

class ContentPreviewSheet extends ConsumerWidget {
  final TrackableContent content;

  const ContentPreviewSheet({super.key, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnime = content is AnimeEntity;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 160,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    content.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.elevated,
                      child: const Icon(Icons.image_not_supported, color: AppTheme.secondaryText),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              content.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isAnime ? 'Anime • ${content.totalProgress} Episodes' : 'Manga • ${content.totalProgress > 0 ? '${content.totalProgress} Chapters' : 'Ongoing'}',
              style: const TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (content.genres.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: content.genres.take(4).map((genre) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.elevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 24),
            if (content.description != null && content.description!.isNotEmpty) ...[
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content.description!,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.primaryText.withOpacity(0.8),
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addToLibrary(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'ADD TO LIBRARY',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToLibrary(BuildContext context, WidgetRef ref) async {
    try {
      if (content is AnimeEntity) {
        await ref.read(animeRepositoryProvider).saveAnime(content as AnimeEntity);
      } else if (content is MangaEntity) {
        await ref.read(mangaRepositoryProvider).saveManga(content as MangaEntity);
      }
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${content.title} to Library'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }
}
