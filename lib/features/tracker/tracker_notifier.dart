import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/core/utils/progress_utils.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/domain/entities/user_session.dart';

class TrackerState {
  final Set<String> busyContentIds;

  const TrackerState({
    this.busyContentIds = const <String>{},
  });

  bool isBusy(String contentId) => busyContentIds.contains(contentId);

  TrackerState copyWith({
    Set<String>? busyContentIds,
  }) {
    return TrackerState(
      busyContentIds: busyContentIds ?? this.busyContentIds,
    );
  }
}

class TrackerUndoAction {
  final String sessionId;
  final TrackableContent previousContent;
  final int delta;

  const TrackerUndoAction({
    required this.sessionId,
    required this.previousContent,
    required this.delta,
  });
}

class TrackerActionResult {
  final String message;
  final String undoneMessage;
  final TrackerUndoAction? undoAction;

  const TrackerActionResult({
    required this.message,
    required this.undoneMessage,
    this.undoAction,
  });
}

class TrackerNotifier extends StateNotifier<TrackerState> {
  final Ref ref;

  TrackerNotifier(this.ref) : super(const TrackerState());

  Future<TrackerActionResult?> logAnimeEpisode(
    AnimeEntity anime, {
    UserEntity? user,
  }) {
    return logAnimeToEpisode(
      anime,
      anime.currentEpisode + 1,
      user: user,
    );
  }

  Future<TrackerActionResult?> logMangaChapter(
    MangaEntity manga, {
    UserEntity? user,
  }) {
    return logMangaToChapter(
      manga,
      manga.currentChapter + 1,
      user: user,
    );
  }

  Future<TrackerActionResult?> logAnimeToEpisode(
    AnimeEntity anime,
    int targetEpisode, {
    UserEntity? user,
  }) async {
    if (!_startBusy(anime.id)) return null;

    try {
      final releaseCap =
          await ref.read(animeReleaseCapProvider(anime.id).future);
      final maxAllowed =
          getMaxAllowedProgress(anime, releaseCap: releaseCap) ?? targetEpisode;
      final safeTarget =
          targetEpisode.clamp(anime.currentEpisode, maxAllowed).toInt();
      final delta = safeTarget - anime.currentEpisode;
      if (delta <= 0) {
        return TrackerActionResult(
          message: 'Only $maxAllowed ${progressUnitLabel(anime)} released so far',
          undoneMessage: 'Nothing changed',
        );
      }

      final now = DateTime.now();
      final sessionId = now.microsecondsSinceEpoch.toString();
      final minutesPerUnit = _animeMinutes(user);
      final session = UserSessionEntity(
        id: sessionId,
        contentId: anime.id,
        contentType: SessionContentType.anime,
        startTime: now.subtract(Duration(minutes: minutesPerUnit * delta)),
        endTime: now,
        unitsConsumed: delta,
      );

      final sessionSaved =
          await ref.read(sessionRepositoryProvider).saveSession(session);
      if (!sessionSaved) {
        throw Exception('Failed to save session');
      }

      await _logDailyActivityDelta(
        date: now,
        minutesDelta: minutesPerUnit * delta,
        isAnime: true,
      );

      final updatedAnime = anime.copyWith(
        currentEpisode: safeTarget,
        status: anime.totalEpisodes > 0 && safeTarget >= anime.totalEpisodes
            ? AnimeStatus.completed
            : AnimeStatus.watching,
        updatedAt: now,
      );

      final animeSaved =
          await ref.read(animeRepositoryProvider).saveAnime(updatedAnime);
      if (!animeSaved) {
        await ref.read(sessionRepositoryProvider).deleteSession(sessionId);
        throw Exception('Failed to update anime progress');
      }

      _invalidateAfterMutation(isAnime: true);

      return TrackerActionResult(
        message: delta == 1 ? 'Logged +1 episode' : 'Logged +$delta episodes',
        undoneMessage: 'Undid anime log',
        undoAction: TrackerUndoAction(
          sessionId: sessionId,
          previousContent: anime,
          delta: delta,
        ),
      );
    } finally {
      _finishBusy(anime.id);
    }
  }

  Future<TrackerActionResult?> logMangaToChapter(
    MangaEntity manga,
    int targetChapter, {
    UserEntity? user,
  }) async {
    if (!_startBusy(manga.id)) return null;

    try {
      final releaseCap = await ref.read(
        mangaReleaseCapForMangaProvider(
          MangaReleaseCapLookup(
            mangaId: manga.id,
            coverImageUrl: manga.coverImage,
            title: manga.title,
          ),
        ).future,
      );
      final maxAllowed =
          getMaxAllowedProgress(manga, releaseCap: releaseCap) ?? targetChapter;
      final safeTarget =
          targetChapter.clamp(manga.currentChapter, maxAllowed).toInt();
      final delta = safeTarget - manga.currentChapter;
      if (delta <= 0) {
        return TrackerActionResult(
          message: 'Only $maxAllowed ${progressUnitLabel(manga)} released so far',
          undoneMessage: 'Nothing changed',
        );
      }

      final now = DateTime.now();
      final sessionId = now.microsecondsSinceEpoch.toString();
      final minutesPerUnit = _mangaMinutes(user);
      final session = UserSessionEntity(
        id: sessionId,
        contentId: manga.id,
        contentType: SessionContentType.manga,
        startTime: now.subtract(Duration(minutes: minutesPerUnit * delta)),
        endTime: now,
        unitsConsumed: delta,
      );

      final sessionSaved =
          await ref.read(sessionRepositoryProvider).saveSession(session);
      if (!sessionSaved) {
        throw Exception('Failed to save session');
      }

      await _logDailyActivityDelta(
        date: now,
        minutesDelta: minutesPerUnit * delta,
        isAnime: false,
      );

      final updatedManga = manga.copyWith(
        currentChapter: safeTarget,
        status: manga.totalChapters > 0 && safeTarget >= manga.totalChapters
            ? MangaStatus.completed
            : MangaStatus.reading,
        updatedAt: now,
      );

      final mangaSaved =
          await ref.read(mangaRepositoryProvider).saveManga(updatedManga);
      if (!mangaSaved) {
        await ref.read(sessionRepositoryProvider).deleteSession(sessionId);
        throw Exception('Failed to update manga progress');
      }

      _invalidateAfterMutation(isAnime: false);

      return TrackerActionResult(
        message: delta == 1 ? 'Logged +1 chapter' : 'Logged +$delta chapters',
        undoneMessage: 'Undid manga log',
        undoAction: TrackerUndoAction(
          sessionId: sessionId,
          previousContent: manga,
          delta: delta,
        ),
      );
    } finally {
      _finishBusy(manga.id);
    }
  }

  Future<TrackerActionResult?> markCompleted(
    TrackableContent content, {
    UserEntity? user,
  }) {
    if (content is AnimeEntity) {
      final target = content.totalEpisodes > 0
          ? content.totalEpisodes
          : content.currentEpisode;
      if (target > content.currentEpisode) {
        return logAnimeToEpisode(content, target, user: user);
      }
      return _updateAnime(
        content.copyWith(
          status: AnimeStatus.completed,
          updatedAt: DateTime.now(),
        ),
        message: 'Marked anime complete',
      );
    }

    final manga = content as MangaEntity;
    final target =
        manga.totalChapters > 0 ? manga.totalChapters : manga.currentChapter;
    if (target > manga.currentChapter) {
      return logMangaToChapter(manga, target, user: user);
    }
    return _updateManga(
      manga.copyWith(
        status: MangaStatus.completed,
        updatedAt: DateTime.now(),
      ),
      message: 'Marked manga complete',
    );
  }

  Future<TrackerActionResult?> updateRating(
    TrackableContent content,
    double rating,
  ) {
    if (content is AnimeEntity) {
      return _updateAnime(
        content.copyWith(
          rating: rating,
          updatedAt: DateTime.now(),
        ),
        message: 'Updated anime rating',
      );
    }

    final manga = content as MangaEntity;
    return _updateManga(
      manga.copyWith(
        rating: rating,
        updatedAt: DateTime.now(),
      ),
      message: 'Updated manga rating',
    );
  }

  Future<TrackerActionResult?> removeFromLibrary(
      TrackableContent content) async {
    if (!_startBusy(content.id)) return null;

    try {
      final deleted = content is AnimeEntity
          ? await ref.read(animeRepositoryProvider).deleteAnime(content.id)
          : await ref.read(mangaRepositoryProvider).deleteManga(content.id);
      if (!deleted) {
        throw Exception('Failed to remove item');
      }

      _invalidateAfterMutation(isAnime: content is AnimeEntity);

      return const TrackerActionResult(
        message: 'Removed from library',
        undoneMessage: 'Removal cannot be undone',
      );
    } finally {
      _finishBusy(content.id);
    }
  }

  Future<void> undoAction(TrackerUndoAction undoAction) async {
    final content = undoAction.previousContent;
    if (!_startBusy(content.id)) return;

    try {
      await ref
          .read(sessionRepositoryProvider)
          .deleteSession(undoAction.sessionId);
      final minutesDelta = content is AnimeEntity
          ? _animeMinutes(ref.read(currentUserProvider).valueOrNull) *
              undoAction.delta
          : _mangaMinutes(ref.read(currentUserProvider).valueOrNull) *
              undoAction.delta;
      await _logDailyActivityDelta(
        date: DateTime.now(),
        minutesDelta: -minutesDelta,
        isAnime: content is AnimeEntity,
      );

      if (content is AnimeEntity) {
        await ref.read(animeRepositoryProvider).saveAnime(content);
        _invalidateAfterMutation(isAnime: true);
      } else if (content is MangaEntity) {
        await ref.read(mangaRepositoryProvider).saveManga(content);
        _invalidateAfterMutation(isAnime: false);
      }
    } finally {
      _finishBusy(content.id);
    }
  }

  Future<TrackerActionResult?> _updateAnime(
    AnimeEntity anime, {
    required String message,
  }) async {
    if (!_startBusy(anime.id)) return null;
    try {
      final saved = await ref.read(animeRepositoryProvider).saveAnime(anime);
      if (!saved) {
        throw Exception('Failed to update anime');
      }
      _invalidateAfterMutation(isAnime: true);
      return TrackerActionResult(
        message: message,
        undoneMessage: 'Update saved',
      );
    } finally {
      _finishBusy(anime.id);
    }
  }

  Future<TrackerActionResult?> _updateManga(
    MangaEntity manga, {
    required String message,
  }) async {
    if (!_startBusy(manga.id)) return null;
    try {
      final saved = await ref.read(mangaRepositoryProvider).saveManga(manga);
      if (!saved) {
        throw Exception('Failed to update manga');
      }
      _invalidateAfterMutation(isAnime: false);
      return TrackerActionResult(
        message: message,
        undoneMessage: 'Update saved',
      );
    } finally {
      _finishBusy(manga.id);
    }
  }

  int _animeMinutes(UserEntity? user) {
    final minutes = user?.defaultAnimeWatchTime ?? 24;
    return minutes < 1 ? 24 : minutes;
  }

  int _mangaMinutes(UserEntity? user) {
    final minutes = user?.defaultMangaReadTime ?? 15;
    return minutes < 1 ? 15 : minutes;
  }

  Future<void> _logDailyActivityDelta({
    required DateTime date,
    required int minutesDelta,
    required bool isAnime,
  }) {
    return ref.read(trackerRepositoryProvider).logActivity(
          date,
          minutesWatched: isAnime ? minutesDelta : null,
          minutesRead: isAnime ? null : minutesDelta,
        );
  }

  void _invalidateAfterMutation({required bool isAnime}) {
    if (isAnime) {
      ref.invalidate(libraryAnimeProvider);
    } else {
      ref.invalidate(libraryMangaProvider);
    }
    ref.invalidate(combinedLibraryProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(dailyActivityProvider);
    ref.invalidate(latestSessionByContentProvider);
    ref.invalidate(userPreferenceProfileProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(retentionReminderProvider);
    ref.invalidate(weeklyWrappedProvider);
    ref.invalidate(monthlyWrappedProvider);
    ref.invalidate(wrappedPromptProvider);
  }

  bool _startBusy(String contentId) {
    if (state.isBusy(contentId)) return false;
    state = state.copyWith(
      busyContentIds: {...state.busyContentIds, contentId},
    );
    return true;
  }

  void _finishBusy(String contentId) {
    final nextBusy = {...state.busyContentIds}..remove(contentId);
    state = state.copyWith(busyContentIds: nextBusy);
  }
}

final trackerNotifierProvider =
    StateNotifierProvider<TrackerNotifier, TrackerState>((ref) {
  return TrackerNotifier(ref);
});
