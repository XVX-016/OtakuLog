import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/features/downloads/downloaded_chapter_store.dart';
import 'package:otakulog/features/downloads/models/downloaded_chapter.dart';

enum DownloadStatus { idle, queued, downloading, done, error }

class ChapterDownloadProgress {
  final DownloadStatus status;
  final double progress;
  final String? errorMessage;

  const ChapterDownloadProgress({
    this.status = DownloadStatus.idle,
    this.progress = 0,
    this.errorMessage,
  });

  ChapterDownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChapterDownloadProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DownloadQueueState {
  final Map<String, ChapterDownloadProgress> chapterProgress;
  final List<String> queuedChapterIds;
  final String? activeChapterId;

  const DownloadQueueState({
    this.chapterProgress = const {},
    this.queuedChapterIds = const [],
    this.activeChapterId,
  });

  ChapterDownloadProgress progressFor(String chapterId) {
    return chapterProgress[chapterId] ?? const ChapterDownloadProgress();
  }

  DownloadQueueState copyWith({
    Map<String, ChapterDownloadProgress>? chapterProgress,
    List<String>? queuedChapterIds,
    String? activeChapterId,
    bool clearActive = false,
  }) {
    return DownloadQueueState(
      chapterProgress: chapterProgress ?? this.chapterProgress,
      queuedChapterIds: queuedChapterIds ?? this.queuedChapterIds,
      activeChapterId: clearActive ? null : (activeChapterId ?? this.activeChapterId),
    );
  }
}

class DownloadRequest {
  final String mangaId;
  final String? mangaDexId;
  final String? mangaTitle;
  final MangaDexChapter chapter;

  const DownloadRequest({
    required this.mangaId,
    this.mangaDexId,
    this.mangaTitle,
    required this.chapter,
  });
}

class DownloadQueueNotifier extends StateNotifier<DownloadQueueState> {
  final Ref ref;
  final DownloadedChapterStore store;
  final Dio dio;
  final Queue<DownloadRequest> _queue = Queue<DownloadRequest>();
  bool _isProcessing = false;

  DownloadQueueNotifier(
    this.ref, {
    required this.store,
    Dio? dio,
  })  : dio = dio ?? Dio(),
        super(const DownloadQueueState());

  Future<void> enqueue({
    required String mangaId,
    String? mangaDexId,
    String? mangaTitle,
    required MangaDexChapter chapter,
  }) async {
    final existing = await store.getByChapterId(chapter.id);
    if (existing != null) {
      _setProgress(
        chapter.id,
        const ChapterDownloadProgress(status: DownloadStatus.done, progress: 1),
      );
      ref.invalidate(downloadedChaptersProvider);
      return;
    }

    if (state.progressFor(chapter.id).status == DownloadStatus.queued ||
        state.progressFor(chapter.id).status == DownloadStatus.downloading) {
      return;
    }

    _queue.add(
      DownloadRequest(
        mangaId: mangaId,
        mangaDexId: mangaDexId,
        mangaTitle: mangaTitle,
        chapter: chapter,
      ),
    );
    _setProgress(
      chapter.id,
      const ChapterDownloadProgress(status: DownloadStatus.queued, progress: 0),
    );
    state = state.copyWith(
      queuedChapterIds: [...state.queuedChapterIds, chapter.id],
    );
    await _pumpQueue();
  }

  Future<void> deleteDownloadedChapter(String chapterId) async {
    await store.delete(chapterId);
    final next = {...state.chapterProgress};
    next.remove(chapterId);
    state = state.copyWith(chapterProgress: next);
    ref.invalidate(downloadedChaptersProvider);
    ref.invalidate(totalDownloadedBytesProvider);
  }

  Future<void> _pumpQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      state = state.copyWith(
        activeChapterId: request.chapter.id,
        queuedChapterIds:
            state.queuedChapterIds.where((id) => id != request.chapter.id).toList(),
      );

      try {
        await _downloadChapter(request);
        _setProgress(
          request.chapter.id,
          const ChapterDownloadProgress(status: DownloadStatus.done, progress: 1),
        );
      } catch (error) {
        _setProgress(
          request.chapter.id,
          ChapterDownloadProgress(
            status: DownloadStatus.error,
            progress: 0,
            errorMessage: 'Download failed',
          ),
        );
      } finally {
        state = state.copyWith(clearActive: true);
      }
    }

    _isProcessing = false;
  }

  Future<void> _downloadChapter(DownloadRequest request) async {
    final preferences = await ref.read(retentionPreferencesProvider.future);
    final chapterPages = await ref.read(mangadexServiceProvider).fetchChapterPages(
          request.chapter.id,
          dataSaver: preferences.preferDataSaverDownloads,
        );
    final chapterDir = await store.chapterDirectory(request.chapter.id);
    final localPaths = <String>[];
    var totalBytes = 0;

    for (var i = 0; i < chapterPages.pages.length; i++) {
      final page = chapterPages.pages[i];
      final ext = _extensionFor(page.primaryUrl);
      final filePath =
          '${chapterDir.path}/page_${(i + 1).toString().padLeft(3, '0')}.$ext';
      await _downloadWithFallback(page, filePath);
      localPaths.add(filePath);
      final file = File(filePath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
      _setProgress(
        request.chapter.id,
        ChapterDownloadProgress(
          status: DownloadStatus.downloading,
          progress: (i + 1) / chapterPages.pages.length,
        ),
      );
    }

    await store.save(
      DownloadedChapter(
        chapterId: request.chapter.id,
        mangaId: request.mangaId,
        mangaDexId: request.mangaDexId,
        mangaTitle: request.mangaTitle,
        chapterLabel: request.chapter.chapterLabel,
        chapterTitle: request.chapter.title,
        localPaths: localPaths,
        totalPages: localPaths.length,
        downloadedAt: DateTime.now(),
        totalBytes: totalBytes,
      ),
    );

    ref.invalidate(downloadedChaptersProvider);
    ref.invalidate(totalDownloadedBytesProvider);
  }

  Future<void> _downloadWithFallback(MangaDexPageAsset asset, String savePath) async {
    try {
      await dio.download(asset.primaryUrl, savePath);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (asset.fallbackUrl != null &&
          statusCode >= 500 &&
          statusCode < 600) {
        await dio.download(asset.fallbackUrl!, savePath);
        return;
      }
      rethrow;
    }
  }

  String _extensionFor(String url) {
    final uri = Uri.tryParse(url);
    final segment = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : url;
    final dot = segment.lastIndexOf('.');
    if (dot == -1 || dot == segment.length - 1) return 'jpg';
    return segment.substring(dot + 1);
  }

  void _setProgress(String chapterId, ChapterDownloadProgress progress) {
    state = state.copyWith(
      chapterProgress: {
        ...state.chapterProgress,
        chapterId: progress,
      },
    );
  }
}

final downloadedChapterStoreProvider = Provider<DownloadedChapterStore>((ref) {
  return DownloadedChapterStore();
});

final downloadedChaptersProvider = FutureProvider<List<DownloadedChapter>>((ref) {
  return ref.watch(downloadedChapterStoreProvider).loadAll();
});

final totalDownloadedBytesProvider = FutureProvider<int>((ref) {
  return ref.watch(downloadedChapterStoreProvider).totalBytes();
});

final downloadQueueNotifierProvider =
    StateNotifierProvider<DownloadQueueNotifier, DownloadQueueState>((ref) {
  return DownloadQueueNotifier(
    ref,
    store: ref.watch(downloadedChapterStoreProvider),
  );
});
