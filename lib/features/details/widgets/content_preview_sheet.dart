import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/utils/progress_utils.dart';
import 'package:otakulog/core/utils/text_sanitizer.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/features/reader/manga_reader_notifier.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';
import 'package:otakulog/features/search/search_notifier.dart';
import 'package:otakulog/features/tracker/tracker_feedback.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';

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

  int get _resolvedTotalChapters {
    final metadataCount = widget.searchItem?.totalCount ?? 0;
    final contentCount = _content.totalProgress;
    final fetchedCount = _totalChapters ?? 0;
    if (fetchedCount > 0) return fetchedCount;
    if (metadataCount > 0) return metadataCount;
    if (contentCount > 0) return contentCount;
    return 0;
  }

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
    _rating = null;
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
    final totalCount = _isAnime ? _content.totalProgress : _resolvedTotalChapters;
    final isInLibrary = widget.searchItem?.inLibrary ?? false;
    final metadata = widget.searchItem;
    final sanitizedDescription =
        stripHtmlTags(metadata?.description ?? _content.description ?? '');
    final manga = _content is MangaEntity ? _content as MangaEntity : null;
    final releaseCap = manga == null
        ? null
        : ref
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
    final maxAllowedProgress = manga == null
        ? null
        : getMaxAllowedProgress(manga, releaseCap: releaseCap);
    final canLogManga = manga != null &&
        (maxAllowedProgress == null || manga.currentChapter < maxAllowedProgress);

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
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'IN LIBRARY',
                        style: TextStyle(
                          color: Colors.white,
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
              if (manga != null) ...[
                const SizedBox(height: 16),
                _buildMangaActionRow(
                  context,
                  manga,
                  canLogManga: canLogManga,
                ),
              ],
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
                      child: ElevatedButton(
                        onPressed: () => _openInLibrary(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.accent,
                        ),
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

  Widget _buildMangaActionRow(
    BuildContext context,
    MangaEntity manga, {
    required bool canLogManga,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final buttons = <Widget>[
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _openMangaReader(context, manga),
              icon: const Icon(Icons.menu_book_outlined),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('READ'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving || !canLogManga
                  ? null
                  : () => _quickLogManga(context, manga),
              icon: const Icon(Icons.add),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('LOG CHAPTER'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
              ),
            ),
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: buttons[0]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: buttons[1]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 12),
            Expanded(child: buttons[1]),
          ],
        );
      },
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
            totalChapters: _resolvedTotalChapters,
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
            content: Text(
              added
                  ? 'Added ${_content.title} to Library'
                  : '${_content.title} is already in Library',
              style: const TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            showCloseIcon: true,
            closeIconColor: Colors.black87,
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
            duration: const Duration(seconds: 5),
            showCloseIcon: true,
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
                totalChapters: existing.totalChapters > 0
                    ? existing.totalChapters
                    : _resolvedTotalChapters,
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
            content: Text(
              'Library item updated',
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
            showCloseIcon: true,
            closeIconColor: Colors.black87,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            duration: const Duration(seconds: 5),
            showCloseIcon: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<MangaEntity> _ensureMangaSaved(MangaEntity manga) async {
    final existing = await ref.read(mangaRepositoryProvider).getMangaById(manga.id);
    if (existing != null) {
      if (existing.totalChapters > 0) return existing;
      final enriched = existing.copyWith(
        totalChapters: _resolvedTotalChapters,
      );
      await ref.read(mangaRepositoryProvider).saveManga(enriched);
      ref.invalidate(libraryMangaProvider);
      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(searchNotifierProvider);
      return enriched;
    }

    final toSave = manga.copyWith(
      totalChapters: _resolvedTotalChapters,
      status: _mangaStatus ?? MangaStatus.reading,
      rating: _rating,
    );
    await ref.read(mangaRepositoryProvider).saveManga(toSave);
    ref.invalidate(libraryMangaProvider);
    ref.invalidate(combinedLibraryProvider);
    ref.invalidate(searchNotifierProvider);
    return toSave;
  }

  Future<void> _openMangaReader(BuildContext context, MangaEntity manga) async {
    final savedManga = await _ensureMangaSaved(manga);
    if (!mounted || !context.mounted) return;
    Navigator.pop(context);
    context.push('/content/${savedManga.id}/manga');
  }

  Future<void> _quickLogManga(BuildContext context, MangaEntity manga) async {
    setState(() => _isSaving = true);
    try {
      final savedManga = await _ensureMangaSaved(manga);
      final result = await ref.read(trackerNotifierProvider.notifier).logMangaChapter(
            savedManga,
            user: ref.read(currentUserProvider).valueOrNull,
          );
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      if (result != null) {
        await showTrackerFeedback(context, ref, result);
      } else {
        await showTrackerMessage(
          context,
          message: 'Unable to log chapter',
        );
      }
    } catch (_) {
      if (!mounted || !context.mounted) return;
      await showTrackerMessage(
        context,
        message: 'Unable to log chapter',
      );
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
