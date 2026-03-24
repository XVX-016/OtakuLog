import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/features/downloads/download_queue_notifier.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';

enum MangaReaderMode { vertical, paged }

class MangaReaderArgs {
  final MangaEntity manga;
  final String? mangaDexId;
  final String? initialChapterId;

  const MangaReaderArgs({
    required this.manga,
    this.mangaDexId,
    this.initialChapterId,
  });
}

class MangaReaderState {
  final List<MangaDexChapter> chapters;
  final MangaDexChapter? currentChapter;
  final List<MangaDexPageAsset> pages;
  final MangaReaderMode mode;
  final int currentPageIndex;
  final bool showChrome;
  final bool isLoadingChapters;
  final bool isLoadingChapter;
  final String? chapterLoadError;
  final String? chaptersLoadError;
  final Set<String> autoLoggedChapterIds;

  const MangaReaderState({
    this.chapters = const [],
    this.currentChapter,
    this.pages = const [],
    this.mode = MangaReaderMode.vertical,
    this.currentPageIndex = 0,
    this.showChrome = true,
    this.isLoadingChapters = false,
    this.isLoadingChapter = false,
    this.chapterLoadError,
    this.chaptersLoadError,
    this.autoLoggedChapterIds = const {},
  });

  bool get hasPages => pages.isNotEmpty;
  bool get isAtLastPage => pages.isNotEmpty && currentPageIndex >= pages.length - 1;

  MangaReaderState copyWith({
    List<MangaDexChapter>? chapters,
    MangaDexChapter? currentChapter,
    bool clearCurrentChapter = false,
    List<MangaDexPageAsset>? pages,
    MangaReaderMode? mode,
    int? currentPageIndex,
    bool? showChrome,
    bool? isLoadingChapters,
    bool? isLoadingChapter,
    String? chapterLoadError,
    bool clearChapterLoadError = false,
    String? chaptersLoadError,
    bool clearChaptersLoadError = false,
    Set<String>? autoLoggedChapterIds,
  }) {
    return MangaReaderState(
      chapters: chapters ?? this.chapters,
      currentChapter:
          clearCurrentChapter ? null : (currentChapter ?? this.currentChapter),
      pages: pages ?? this.pages,
      mode: mode ?? this.mode,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      showChrome: showChrome ?? this.showChrome,
      isLoadingChapters: isLoadingChapters ?? this.isLoadingChapters,
      isLoadingChapter: isLoadingChapter ?? this.isLoadingChapter,
      chapterLoadError:
          clearChapterLoadError ? null : (chapterLoadError ?? this.chapterLoadError),
      chaptersLoadError:
          clearChaptersLoadError ? null : (chaptersLoadError ?? this.chaptersLoadError),
      autoLoggedChapterIds: autoLoggedChapterIds ?? this.autoLoggedChapterIds,
    );
  }
}

class MangaReaderNotifier extends StateNotifier<MangaReaderState> {
  final Ref ref;
  final MangaReaderArgs args;

  MangaReaderNotifier(this.ref, this.args) : super(const MangaReaderState()) {
    loadInitial();
  }

  MangadexService get _service => ref.read(mangadexServiceProvider);

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoadingChapters: true,
      clearChaptersLoadError: true,
    );

    try {
      final chapters = await _service.fetchChapterFeed(
        args.mangaDexId ?? args.manga.id,
        coverImageUrl: args.manga.coverImage,
        title: args.manga.title,
      );
      if (chapters.isEmpty) {
        state = state.copyWith(
          chapters: const [],
          isLoadingChapters: false,
          chaptersLoadError: 'No readable English chapters found.',
        );
        return;
      }

      state = state.copyWith(
        chapters: chapters,
        isLoadingChapters: false,
        clearChaptersLoadError: true,
      );

      final initial = _pickInitialChapter(chapters);
      await selectChapter(initial);
    } catch (error) {
      final offlineInitial = await _loadOfflineInitialChapter();
      if (offlineInitial != null) {
        state = state.copyWith(
          chapters: [offlineInitial],
          isLoadingChapters: false,
          clearChaptersLoadError: true,
        );
        await selectChapter(offlineInitial);
        return;
      }

      state = state.copyWith(
        isLoadingChapters: false,
        chaptersLoadError: 'Could not load chapter list.',
      );
    }
  }

  Future<MangaDexChapter?> _loadOfflineInitialChapter() async {
    final chapterId = args.initialChapterId;
    if (chapterId == null || chapterId.trim().isEmpty) return null;

    final downloaded =
        await ref.read(downloadedChapterStoreProvider).getByChapterId(chapterId);
    if (downloaded == null) return null;

    return MangaDexChapter(
      id: downloaded.chapterId,
      title: (downloaded.chapterTitle?.trim().isNotEmpty ?? false)
          ? downloaded.chapterTitle!.trim()
          : 'Downloaded for offline reading',
      chapterLabel: (downloaded.chapterLabel?.trim().isNotEmpty ?? false)
          ? downloaded.chapterLabel!.trim()
          : 'Offline chapter',
      chapterNumber: double.infinity,
      chapterText: '',
      volumeText: '',
      pageCount: downloaded.totalPages,
    );
  }

  MangaDexChapter _pickInitialChapter(List<MangaDexChapter> chapters) {
    if (args.initialChapterId != null) {
      for (final chapter in chapters) {
        if (chapter.id == args.initialChapterId) return chapter;
      }
    }

    for (final chapter in chapters) {
      final chapterInt = int.tryParse(chapter.chapterText);
      if (chapterInt != null && chapterInt > args.manga.currentChapter) {
        return chapter;
      }
    }
    return chapters.first;
  }

  Future<void> selectChapter(MangaDexChapter chapter) async {
    state = state.copyWith(
      currentChapter: chapter,
      pages: const [],
      currentPageIndex: 0,
      isLoadingChapter: true,
      clearChapterLoadError: true,
    );

    try {
      final downloaded =
          await ref.read(downloadedChapterStoreProvider).getByChapterId(chapter.id);
      final pages = downloaded != null
          ? downloaded.localPaths
              .asMap()
              .entries
              .map((entry) => MangaDexPageAsset(
                    index: entry.key,
                    primaryUrl: entry.value,
                    localPath: entry.value,
                  ))
              .toList()
          : (await _service.fetchChapterPages(chapter.id)).pages;
      state = state.copyWith(
        currentChapter: chapter,
        pages: pages,
        currentPageIndex: 0,
        isLoadingChapter: false,
        clearChapterLoadError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingChapter: false,
        chapterLoadError: 'Could not load chapter pages.',
      );
    }
  }

  void setMode(MangaReaderMode mode) {
    state = state.copyWith(mode: mode);
  }

  void toggleMode() {
    setMode(
      state.mode == MangaReaderMode.vertical
          ? MangaReaderMode.paged
          : MangaReaderMode.vertical,
    );
  }

  void toggleChrome() {
    state = state.copyWith(showChrome: !state.showChrome);
  }

  void setChromeVisible(bool visible) {
    if (state.showChrome == visible) return;
    state = state.copyWith(showChrome: visible);
  }

  Future<void> setCurrentPageIndex(int index) async {
    final clamped = state.pages.isEmpty
        ? 0
        : index.clamp(0, state.pages.length - 1).toInt();
    if (clamped == state.currentPageIndex && !state.isAtLastPage) {
      return;
    }

    state = state.copyWith(currentPageIndex: clamped);
    await _maybeAutoLogChapter();
  }

  Future<void> retryCurrentChapter() async {
    final current = state.currentChapter;
    if (current == null) return;
    await selectChapter(current);
  }

  Future<void> goToAdjacentChapter(int delta) async {
    final current = state.currentChapter;
    if (current == null) return;
    final currentIndex = state.chapters.indexWhere((chapter) => chapter.id == current.id);
    if (currentIndex == -1) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= state.chapters.length) return;
    await selectChapter(state.chapters[nextIndex]);
  }

  Future<void> _maybeAutoLogChapter() async {
    final chapter = state.currentChapter;
    if (chapter == null || !state.isAtLastPage) return;
    if (state.autoLoggedChapterIds.contains(chapter.id)) return;

    final existing = await ref.read(mangaByIdProvider(args.manga.id).future);
    final currentManga = existing ?? args.manga;
    final targetChapter = _targetProgressForChapter(currentManga, chapter);
    if (targetChapter <= currentManga.currentChapter) {
      state = state.copyWith(
        autoLoggedChapterIds: {...state.autoLoggedChapterIds, chapter.id},
      );
      return;
    }

    await ref.read(trackerNotifierProvider.notifier).logMangaToChapter(
          currentManga,
          targetChapter,
          user: ref.read(currentUserProvider).valueOrNull,
        );

    state = state.copyWith(
      autoLoggedChapterIds: {...state.autoLoggedChapterIds, chapter.id},
    );
  }

  int _targetProgressForChapter(MangaEntity manga, MangaDexChapter chapter) {
    final parsedInt = int.tryParse(chapter.chapterText);
    if (parsedInt != null) {
      return parsedInt > manga.currentChapter ? parsedInt : manga.currentChapter + 1;
    }

    if (chapter.chapterNumber.isFinite) {
      final rounded = chapter.chapterNumber.floor();
      if (rounded > manga.currentChapter) {
        return rounded;
      }
    }

    return manga.currentChapter + 1;
  }
}

final mangaReaderNotifierProvider = StateNotifierProvider.autoDispose
    .family<MangaReaderNotifier, MangaReaderState, MangaReaderArgs>((ref, args) {
  return MangaReaderNotifier(ref, args);
});
