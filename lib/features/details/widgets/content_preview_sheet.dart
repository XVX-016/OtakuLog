import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/utils/text_sanitizer.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';
import 'package:goon_tracker/features/search/search_notifier.dart';

class ContentPreviewSheet extends ConsumerStatefulWidget {
  final TrackableContent? content;
  final SearchResultItem? searchItem;

  const ContentPreviewSheet({
    super.key,
    this.content,
    this.searchItem,
  }) : assert(content != null || searchItem != null);

  @override
  ConsumerState<ContentPreviewSheet> createState() => _ContentPreviewSheetState();
}

class _ContentPreviewSheetState extends ConsumerState<ContentPreviewSheet> {
  int? _totalChapters;
  bool _isSaving = false;
  AnimeStatus? _animeStatus;
  MangaStatus? _mangaStatus;
  double? _rating;

  TrackableContent get _content => widget.searchItem?.content ?? widget.content!;

  bool get _isAnime => _content is AnimeEntity;

  @override
  void initState() {
    super.initState();
    if (_content is MangaEntity) {
      _fetchChapters();
      _mangaStatus = (_content as MangaEntity).status;
    }
    if (_content is AnimeEntity) {
      _animeStatus = (_content as AnimeEntity).status;
    }
    _rating = _content.rating;
  }

  Future<void> _fetchChapters() async {
    if (_content.id.startsWith('nhentai:')) {
      return;
    }
    final count = await ref.read(mangadexServiceProvider).fetchChapterCount(_content.id);
    if (mounted) {
      setState(() {
        _totalChapters = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _isAnime ? _content.totalProgress : (_totalChapters ?? _content.totalProgress);
    final isInLibrary = widget.searchItem?.inLibrary ?? false;
    final metadata = widget.searchItem;
    final sanitizedDescription =
        stripHtmlTags(metadata?.description ?? _content.description ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                    imageUrl: _content.coverImage,
                    title: _content.title,
                    badge: _isAnime ? 'ANIME' : 'MANGA',
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _content.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isInLibrary)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'IN LIBRARY',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(_isAnime ? 'Anime' : 'Manga'),
                  _infoChip(_countLabel(totalCount)),
                  if (metadata?.score != null) _infoChip('Score ${metadata!.score!.toStringAsFixed(1)}'),
                  if ((metadata?.statusLabel ?? '').isNotEmpty) _infoChip(metadata!.statusLabel!),
                ],
              ),
              if ((metadata?.creatorNames ?? const []).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'CREATORS',
                  style: _sectionLabelStyle(),
                ),
                const SizedBox(height: 6),
                Text(
                  metadata!.creatorNames.join(', '),
                  style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                ),
              ],
              if ((metadata?.tags ?? _content.genres).isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('TAGS', style: _sectionLabelStyle()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (metadata?.tags ?? _content.genres)
                      .take(6)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.elevated,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (sanitizedDescription.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('DESCRIPTION', style: _sectionLabelStyle()),
                const SizedBox(height: 8),
                Text(
                  sanitizedDescription,
                  style: TextStyle(
                    color: AppTheme.primaryText.withOpacity(0.8),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('STATUS', style: _sectionLabelStyle()),
              const SizedBox(height: 8),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              Text('INITIAL RATING', style: _sectionLabelStyle()),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star.toDouble()),
                    icon: Icon(
                      (_rating ?? 0) >= star ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              if (isInLibrary)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _openInLibrary(context),
                        child: const Text('OPEN IN LIBRARY'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _updateExisting(context),
                        child: Text(_isSaving ? 'UPDATING...' : 'UPDATE STATUS'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _addToLibrary(context),
                    child: Text(_isSaving ? 'ADDING...' : 'ADD TO LIBRARY'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionLabelStyle() {
    return const TextStyle(
      color: AppTheme.secondaryText,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _countLabel(int totalCount) {
    if (totalCount <= 0) {
      return _isAnime ? 'Episodes unknown' : 'Chapters unknown';
    }
    return _isAnime ? '$totalCount Episodes' : '$totalCount Chapters';
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: _isAnime
            ? DropdownButton<AnimeStatus>(
                value: _animeStatus ?? AnimeStatus.watching,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                iconEnabledColor: AppTheme.primaryText,
                items: AnimeStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _animeStatus = value);
                  }
                },
              )
            : DropdownButton<MangaStatus>(
                value: _mangaStatus ?? MangaStatus.reading,
                isExpanded: true,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                iconEnabledColor: AppTheme.primaryText,
                items: MangaStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(
                            status.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _mangaStatus = value);
                  }
                },
              ),
      ),
    );
  }

  Future<void> _addToLibrary(BuildContext context) async {
    setState(() => _isSaving = true);
    var added = false;
    try {
      if (_content is AnimeEntity) {
        final existing = await ref.read(animeRepositoryProvider).getAnimeById(_content.id);
        if (existing == null) {
          final anime = (_content as AnimeEntity).copyWith(
            status: _animeStatus ?? AnimeStatus.watching,
            rating: _rating,
          );
          final success = await ref.read(animeRepositoryProvider).saveAnime(anime);
          if (!success) throw Exception('Failed to add anime');
          ref.invalidate(libraryAnimeProvider);
          added = true;
        }
      } else if (_content is MangaEntity) {
        final existing = await ref.read(mangaRepositoryProvider).getMangaById(_content.id);
        if (existing == null) {
          final manga = (_content as MangaEntity).copyWith(
            totalChapters: _totalChapters ?? _content.totalProgress,
            status: _mangaStatus ?? MangaStatus.reading,
            rating: _rating,
          );
          final success = await ref.read(mangaRepositoryProvider).saveManga(manga);
          if (!success) throw Exception('Failed to add manga');
          ref.invalidate(libraryMangaProvider);
          added = true;
        }
      }

      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(searchNotifierProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(added ? 'Added ${_content.title} to Library' : '${_content.title} is already in Library'),
            backgroundColor: added ? Colors.green[700] : AppTheme.elevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateExisting(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      if (_content is AnimeEntity) {
        final existing = await ref.read(animeRepositoryProvider).getAnimeById(_content.id);
        if (existing != null) {
          await ref.read(animeRepositoryProvider).saveAnime(existing.copyWith(
                status: _animeStatus ?? existing.status,
                rating: _rating,
              ));
          ref.invalidate(libraryAnimeProvider);
        }
      } else if (_content is MangaEntity) {
        final existing = await ref.read(mangaRepositoryProvider).getMangaById(_content.id);
        if (existing != null) {
          await ref.read(mangaRepositoryProvider).saveManga(existing.copyWith(
                status: _mangaStatus ?? existing.status,
                rating: _rating,
              ));
          ref.invalidate(libraryMangaProvider);
        }
      }

      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(searchNotifierProvider);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library item updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openInLibrary(BuildContext context) {
    final type = _isAnime ? 'anime' : 'manga';
    Navigator.pop(context);
    context.push('/content/${_content.id}/$type');
  }
}
