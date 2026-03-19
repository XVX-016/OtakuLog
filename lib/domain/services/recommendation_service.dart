import 'dart:math';

import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';

class UserPreferenceProfile {
  final Map<String, double> topGenres;
  final Map<String, double> topTags;
  final SessionContentType preferredMedium;
  final double avgSessionLength;
  final int animeMinutes;
  final int mangaMinutes;
  final int currentStreak;
  final double signalStrength;

  const UserPreferenceProfile({
    this.topGenres = const {},
    this.topTags = const {},
    this.preferredMedium = SessionContentType.anime,
    this.avgSessionLength = 0,
    this.animeMinutes = 0,
    this.mangaMinutes = 0,
    this.currentStreak = 0,
    this.signalStrength = 0,
  });

  bool get hasStrongSignal => signalStrength >= 1.0;
}

class PersonalizedRecommendation {
  final SearchResultItem item;
  final double score;
  final String reason;
  final bool isExploratory;

  const PersonalizedRecommendation({
    required this.item,
    required this.score,
    required this.reason,
    this.isExploratory = false,
  });

  String get explanationText => reason;

  Map<String, dynamic> toJson() {
    final content = item.content;
    return {
      'score': score,
      'reason': reason,
      'isExploratory': isExploratory,
      'item': {
        'id': item.id,
        'medium': item.medium.name,
        'tags': item.tags,
        'description': item.description,
        'score': item.score,
        'isAdult': item.isAdult,
        'statusLabel': item.statusLabel,
        'creatorNames': item.creatorNames,
        'totalCount': item.totalCount,
        'inLibrary': item.inLibrary,
        'content': {
          'id': content.id,
          'title': content.title,
          'coverImage': content.coverImage,
          'currentProgress': content.currentProgress,
          'totalProgress': content.totalProgress,
          'rating': content.rating,
          'genres': content.genres,
          'description': content.description,
          'updatedAt': content.updatedAt.toIso8601String(),
          'type': content is AnimeEntity ? 'anime' : 'manga',
          'status': content is AnimeEntity
              ? content.status.name
              : (content as MangaEntity).status.name,
          'isAdult': content is MangaEntity ? content.isAdult : item.isAdult,
        },
      },
    };
  }

  factory PersonalizedRecommendation.fromJson(Map<String, dynamic> json) {
    final rawItem = (json['item'] as Map).cast<String, dynamic>();
    final rawContent = (rawItem['content'] as Map).cast<String, dynamic>();
    final medium = SearchMedium.values.firstWhere(
      (value) => value.name == rawItem['medium'],
      orElse: () => SearchMedium.anime,
    );

    final content = rawContent['type'] == 'manga'
        ? MangaEntity(
            id: rawContent['id'].toString(),
            title: rawContent['title']?.toString() ?? 'Unknown',
            coverImage: rawContent['coverImage']?.toString() ?? '',
            totalChapters: (rawContent['totalProgress'] as num?)?.toInt() ?? 0,
            currentChapter: (rawContent['currentProgress'] as num?)?.toInt() ?? 0,
            status: MangaStatus.values.firstWhere(
              (value) => value.name == rawContent['status'],
              orElse: () => MangaStatus.reading,
            ),
            rating: (rawContent['rating'] as num?)?.toDouble(),
            genres: (rawContent['genres'] as List? ?? const []).map((tag) => tag.toString()).toList(),
            description: rawContent['description']?.toString(),
            isAdult: rawContent['isAdult'] == true,
            createdAt: DateTime.tryParse(rawContent['updatedAt']?.toString() ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(rawContent['updatedAt']?.toString() ?? '') ?? DateTime.now(),
          )
        : AnimeEntity(
            id: rawContent['id'].toString(),
            title: rawContent['title']?.toString() ?? 'Unknown',
            coverImage: rawContent['coverImage']?.toString() ?? '',
            totalEpisodes: (rawContent['totalProgress'] as num?)?.toInt() ?? 0,
            currentEpisode: (rawContent['currentProgress'] as num?)?.toInt() ?? 0,
            status: AnimeStatus.values.firstWhere(
              (value) => value.name == rawContent['status'],
              orElse: () => AnimeStatus.watching,
            ),
            rating: (rawContent['rating'] as num?)?.toDouble(),
            genres: (rawContent['genres'] as List? ?? const []).map((tag) => tag.toString()).toList(),
            description: rawContent['description']?.toString(),
            createdAt: DateTime.tryParse(rawContent['updatedAt']?.toString() ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(rawContent['updatedAt']?.toString() ?? '') ?? DateTime.now(),
          );

    return PersonalizedRecommendation(
      item: SearchResultItem(
        id: rawItem['id'].toString(),
        content: content,
        medium: medium,
        tags: (rawItem['tags'] as List? ?? const []).map((tag) => tag.toString()).toList(),
        description: rawItem['description']?.toString(),
        score: (rawItem['score'] as num?)?.toDouble(),
        isAdult: rawItem['isAdult'] == true,
        statusLabel: rawItem['statusLabel']?.toString(),
        creatorNames: (rawItem['creatorNames'] as List? ?? const []).map((name) => name.toString()).toList(),
        totalCount: (rawItem['totalCount'] as num?)?.toInt(),
        inLibrary: rawItem['inLibrary'] == true,
      ),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reason: json['reason']?.toString() ?? 'Picked for you',
      isExploratory: json['isExploratory'] == true,
    );
  }
}

class RetentionReminder {
  final String title;
  final String message;
  final String actionLabel;
  final DateTime? scheduledFor;

  const RetentionReminder({
    required this.title,
    required this.message,
    required this.actionLabel,
    this.scheduledFor,
  });
}

class RecommendationService {
  static const int refreshMinutesThreshold = 30;

  UserPreferenceProfile buildProfile(
    List<UserSessionEntity> sessions,
    List<TrackableContent> library, {
    int currentStreak = 0,
  }) {
    final libraryById = {
      for (final item in library) item.id: item,
    };
    final genreWeights = <String, double>{};
    final tagWeights = <String, double>{};
    var animeMinutes = 0;
    var mangaMinutes = 0;
    var totalSessionMinutes = 0;

    for (final item in library) {
      final weight = _libraryStatusWeight(item);
      for (final genre in item.genres) {
        final normalized = genre.trim();
        if (normalized.isEmpty) continue;
        genreWeights.update(normalized, (value) => value + weight, ifAbsent: () => weight);
        tagWeights.update(normalized, (value) => value + (weight / 2), ifAbsent: () => weight / 2);
      }
    }

    for (final session in sessions) {
      totalSessionMinutes += session.totalMinutes;
      final item = libraryById[session.contentId];
      if (item == null) continue;

      final sessionWeight = max(1, session.totalMinutes).toDouble();
      for (final genre in item.genres) {
        final normalized = genre.trim();
        if (normalized.isEmpty) continue;
        genreWeights.update(normalized, (value) => value + sessionWeight, ifAbsent: () => sessionWeight);
        tagWeights.update(normalized, (value) => value + (sessionWeight * 0.7), ifAbsent: () => sessionWeight * 0.7);
      }

      if (session.contentType == SessionContentType.anime) {
        animeMinutes += session.totalMinutes;
      } else {
        mangaMinutes += session.totalMinutes;
      }
    }

    final normalizedGenres = _normalizeMap(genreWeights);
    final normalizedTags = _normalizeMap(tagWeights);
    final avgSessionLength = sessions.isEmpty ? 0.0 : totalSessionMinutes.toDouble() / sessions.length.toDouble();
    final signalStrength = normalizedGenres.isEmpty && normalizedTags.isEmpty
        ? 0.0
        : min<double>(3, sessions.length / 4) + min<double>(2, library.length / 6);

    return UserPreferenceProfile(
      topGenres: normalizedGenres,
      topTags: normalizedTags,
      preferredMedium: animeMinutes >= mangaMinutes ? SessionContentType.anime : SessionContentType.manga,
      avgSessionLength: avgSessionLength,
      animeMinutes: animeMinutes,
      mangaMinutes: mangaMinutes,
      currentStreak: currentStreak,
      signalStrength: signalStrength,
    );
  }

  List<String> topGenres(UserPreferenceProfile profile, {int limit = 5}) {
    return _sortedKeys(profile.topGenres, limit);
  }

  List<String> topTags(UserPreferenceProfile profile, {int limit = 5}) {
    return _sortedKeys(profile.topTags, limit);
  }

  bool shouldRefreshRecommendations({
    required DateTime now,
    required DateTime? lastRefreshAt,
    required int totalMinutes,
    required int lastRefreshMinutesTotal,
    required int libraryCount,
    required int lastRefreshLibraryCount,
    required String librarySignature,
    required String? lastRefreshLibrarySignature,
  }) {
    if (lastRefreshAt == null) return true;
    if (now.difference(lastRefreshAt) >= const Duration(days: 1)) return true;
    if (totalMinutes - lastRefreshMinutesTotal >= refreshMinutesThreshold) return true;
    if (libraryCount != lastRefreshLibraryCount) return true;
    if (librarySignature != lastRefreshLibrarySignature) return true;
    return false;
  }

  List<PersonalizedRecommendation> buildRecommendations({
    required UserPreferenceProfile profile,
    required List<TrackableContent> library,
    required List<SearchResultItem> candidates,
  }) {
    final libraryIds = library.map((item) => item.id).toSet();
    final completedIds = library.where(_isCompleted).map((item) => item.id).toSet();
    final preferredGenres = topGenres(profile);
    final preferredTags = topTags(profile);

    final scored = <PersonalizedRecommendation>[];
    for (final candidate in candidates) {
      if (libraryIds.contains(candidate.id) || completedIds.contains(candidate.id)) {
        continue;
      }

      final genresLower = candidate.content.genres.map((genre) => genre.toLowerCase()).toSet();
      final tagsLower = candidate.tags.map((tag) => tag.toLowerCase()).toSet();
      final genreMatches = preferredGenres.where((genre) => genresLower.contains(genre.toLowerCase())).toList();
      final tagMatches = preferredTags.where((tag) => tagsLower.contains(tag.toLowerCase())).toList();

      var score = 0.0;
      score += genreMatches.length * 4.0;
      score += tagMatches.length * 2.0;
      if (candidate.score != null) score += candidate.score! / 4;
      if (candidate.medium == SearchMedium.anime && profile.preferredMedium == SessionContentType.anime) {
        score += 1.2;
      }
      if (candidate.medium == SearchMedium.manga && profile.preferredMedium == SessionContentType.manga) {
        score += 1.2;
      }

      final isExploratory = genreMatches.isEmpty && tagMatches.isEmpty;
      scored.add(
        PersonalizedRecommendation(
          item: candidate,
          score: score,
          reason: _buildReason(profile, candidate, genreMatches, tagMatches, isExploratory),
          isExploratory: isExploratory,
        ),
      );
    }

    final personalized = scored.where((item) => !item.isExploratory).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final exploratory = scored.where((item) => item.isExploratory).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final targetCount = min(10, scored.length);
    final personalizedTarget = (targetCount * 0.7).ceil();
    final results = <PersonalizedRecommendation>[
      ...personalized.take(personalizedTarget),
      ...exploratory.take(max(0, targetCount - personalizedTarget)),
    ];

    if (results.length < targetCount) {
      for (final item in personalized.skip(results.length)) {
        if (results.any((existing) => existing.item.id == item.item.id)) continue;
        results.add(item);
        if (results.length == targetCount) break;
      }
    }

    return results;
  }

  RetentionReminder buildReminder({
    required List<UserSessionEntity> sessions,
    required List<TrackableContent> library,
    required UserPreferenceProfile profile,
    required bool remindersEnabled,
    required DateTime? lastAppOpenedAt,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final todayMinutes = sessions
        .where((session) => !session.endTime.isBefore(todayStart))
        .fold<int>(0, (sum, session) => sum + session.totalMinutes);

    if (!remindersEnabled) {
      return const RetentionReminder(
        title: 'Reminders are paused',
        message: 'Turn reminders back on in Settings whenever you want a nudge.',
        actionLabel: 'Settings',
      );
    }

    if (todayMinutes == 0 && profile.currentStreak > 0) {
      return RetentionReminder(
        title: 'Protect your streak',
        message: 'You are on a ${profile.currentStreak}-day run. One quick log keeps it going.',
        actionLabel: 'Log now',
        scheduledFor: _defaultReminderTime(current),
      );
    }

    final activeItem = library.where(_isInProgress).cast<TrackableContent?>().firstWhere(
          (item) => item != null,
          orElse: () => null,
        );
    if (activeItem != null) {
      return RetentionReminder(
        title: 'Pick up where you left off',
        message:
            'Your next ${activeItem is AnimeEntity ? 'episode' : 'chapter'} of ${activeItem.title} is waiting.',
        actionLabel: 'Continue',
        scheduledFor: _defaultReminderTime(current),
      );
    }

    if (lastAppOpenedAt == null || current.difference(lastAppOpenedAt) > const Duration(days: 7)) {
      return RetentionReminder(
        title: 'Jump back in when ready',
        message: 'Your wrapped and recommendations update once you start logging again.',
        actionLabel: 'Discover',
      );
    }

    return RetentionReminder(
      title: 'Build today\'s stats',
      message: 'A quick session will sharpen your recommendations and keep your wrapped growing.',
      actionLabel: 'Discover',
      scheduledFor: _defaultReminderTime(current),
    );
  }

  int milestoneForStreak(int streak) {
    if (streak >= 30) return 30;
    if (streak >= 7) return 7;
    if (streak >= 3) return 3;
    return 0;
  }

  String milestoneLabel(int milestone) {
    switch (milestone) {
      case 30:
        return 'Committed';
      case 7:
        return 'Consistent';
      case 3:
        return 'Getting started';
      default:
        return 'Start your streak today';
    }
  }

  DateTime _defaultReminderTime(DateTime now) {
    return DateTime(now.year, now.month, now.day, 19);
  }

  bool _isCompleted(TrackableContent item) {
    if (item is AnimeEntity) return item.status == AnimeStatus.completed;
    return (item as MangaEntity).status == MangaStatus.completed;
  }

  bool _isInProgress(TrackableContent item) {
    if (item is AnimeEntity) return item.status == AnimeStatus.watching;
    return (item as MangaEntity).status == MangaStatus.reading;
  }

  double _libraryStatusWeight(TrackableContent item) {
    if (_isCompleted(item)) return 3;
    if (_isInProgress(item)) return 2;
    return 1;
  }

  Map<String, double> _normalizeMap(Map<String, double> source) {
    if (source.isEmpty) return const {};
    final maxValue = source.values.fold<double>(0, max);
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {
      for (final entry in entries.take(6))
        entry.key: maxValue <= 0 ? 0 : entry.value / maxValue,
    };
  }

  List<String> _sortedKeys(Map<String, double> source, int limit) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((entry) => entry.key).toList();
  }

  String _buildReason(
    UserPreferenceProfile profile,
    SearchResultItem candidate,
    List<String> genreMatches,
    List<String> tagMatches,
    bool isExploratory,
  ) {
    if (genreMatches.isNotEmpty) {
      final picked = genreMatches.take(2).join(' & ');
      return 'Because you watch $picked';
    }
    if (tagMatches.isNotEmpty) {
      return 'Based on your recent ${tagMatches.first.toLowerCase()} picks';
    }
    if (candidate.medium == SearchMedium.anime && profile.preferredMedium == SessionContentType.anime) {
      return 'Similar to your in-progress anime';
    }
    if (candidate.medium == SearchMedium.manga && profile.preferredMedium == SessionContentType.manga) {
      return 'Based on your recent reads';
    }
    return isExploratory ? 'A strong exploratory pick' : 'Picked for you';
  }
}
