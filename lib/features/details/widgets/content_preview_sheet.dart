import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ContentPreviewSheet extends ConsumerStatefulWidget {
  final TrackableContent content;

  const ContentPreviewSheet({super.key, required this.content});

  @override
  ConsumerState<ContentPreviewSheet> createState() => _ContentPreviewSheetState();
}

class _ContentPreviewSheetState extends ConsumerState<ContentPreviewSheet> {
  int? _totalChapters;

  @override
  void initState() {
    super.initState();
    if (widget.content is MangaEntity) {
      _fetchChapters();
    }
  }

  Future<void> _fetchChapters() async {
    final count = await ref.read(mangadexServiceProvider).fetchChapterCount(widget.content.id);
    if (mounted) {
      setState(() {
        _totalChapters = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = widget.content is AnimeEntity;
    final totalProgress = isAnime ? widget.content.totalProgress : (_totalChapters ?? widget.content.totalProgress);
    
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
                  child: CachedNetworkImage(
                    imageUrl: widget.content.coverImage,
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
            ),
            const SizedBox(height: 24),
            Text(
              widget.content.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isAnime ? 'Anime • $totalProgress Episodes' : 'Manga • ${totalProgress > 0 ? '$totalProgress Chapters' : 'Ongoing'}',
              style: const TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (widget.content.genres.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.content.genres.take(4).map((genre) => Container(
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
            if (widget.content.description != null && widget.content.description!.isNotEmpty) ...[
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
                widget.content.description!,
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
                onPressed: () => _addToLibrary(context),
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

  Future<void> _addToLibrary(BuildContext context) async {
    try {
      bool success = false;
      bool alreadyInLibrary = false;

      if (widget.content is AnimeEntity) {
        final existing = await ref.read(animeRepositoryProvider).getAnimeById(widget.content.id);
        if (existing != null) {
          alreadyInLibrary = true;
        } else {
          success = await ref.read(animeRepositoryProvider).saveAnime(widget.content as AnimeEntity);
          if (success) ref.invalidate(libraryAnimeProvider);
        }
      } else if (widget.content is MangaEntity) {
        final existing = await ref.read(mangaRepositoryProvider).getMangaById(widget.content.id);
        if (existing != null) {
          alreadyInLibrary = true;
        } else {
          final manga = widget.content as MangaEntity;
          final updatedManga = manga.copyWith(
            totalChapters: _totalChapters ?? manga.totalChapters,
          );
          success = await ref.read(mangaRepositoryProvider).saveManga(updatedManga);
          if (success) ref.invalidate(libraryMangaProvider);
        }
      }

      if (alreadyInLibrary) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This series is already in your library station.'),
              backgroundColor: AppTheme.elevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (success) {
        ref.invalidate(combinedLibraryProvider);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${widget.content.title} to Library'),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        throw Exception('Failed to save to library');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
