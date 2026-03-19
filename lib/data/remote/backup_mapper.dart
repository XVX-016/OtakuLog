import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/features/cloud/models/backup_payload.dart';

class BackupPreview {
  final DateTime exportedAt;
  final int libraryCount;
  final int sessionsCount;
  final String? profileName;

  const BackupPreview({
    required this.exportedAt,
    required this.libraryCount,
    required this.sessionsCount,
    required this.profileName,
  });
}

class BackupMapper {
  BackupPayload exportPayload({
    required UserEntity? profile,
    required List<TrackableContent> library,
    required List<UserSessionEntity> sessions,
    required RetentionPreferences retentionPreferences,
  }) {
    final exportedAt = DateTime.now();
    final lastWrite = _resolveLastWriteTimestamp(profile, library, retentionPreferences);
    return BackupPayload(
      exportedAt: exportedAt,
      lastWriteTimestamp: lastWrite,
      profile: profile == null ? null : _userToJson(profile),
      library: library.map(_contentToJson).toList(),
      sessions: sessions.map(_sessionToJson).toList(),
      retentionPreferences: retentionPreferences.toJson(),
    );
  }

  BackupPreview buildPreview(BackupPayload payload) {
    final profile = payload.profile;
    return BackupPreview(
      exportedAt: payload.exportedAt,
      libraryCount: payload.library.length,
      sessionsCount: payload.sessions.length,
      profileName: profile?['name']?.toString(),
    );
  }

  UserEntity? profileFromPayload(BackupPayload payload) {
    final profile = payload.profile;
    if (profile == null) return null;
    return _userFromJson(profile);
  }

  List<TrackableContent> libraryFromPayload(BackupPayload payload) {
    return payload.library.map(_contentFromJson).toList();
  }

  List<UserSessionEntity> sessionsFromPayload(BackupPayload payload) {
    return payload.sessions.map(_sessionFromJson).toList();
  }

  RetentionPreferences retentionPreferencesFromPayload(BackupPayload payload) {
    return payload.retentionPreferences == null
        ? const RetentionPreferences()
        : RetentionPreferences.fromJson(payload.retentionPreferences!);
  }

  Map<String, dynamic> _userToJson(UserEntity user) {
    return {
      'id': user.id,
      'name': user.name,
      'avatarPath': user.avatarPath,
      'createdAt': user.createdAt.toIso8601String(),
      'updatedAt': user.updatedAt.toIso8601String(),
      'defaultSearchType': user.defaultSearchType,
      'defaultContentRating': user.defaultContentRating,
      'defaultAnimeWatchTime': user.defaultAnimeWatchTime,
      'defaultMangaReadTime': user.defaultMangaReadTime,
      'filter18Plus': user.filter18Plus,
    };
  }

  UserEntity _userFromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id']?.toString() ?? 'local_user',
      name: json['name']?.toString() ?? 'Pilot',
      avatarPath: json['avatarPath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      defaultSearchType: json['defaultSearchType']?.toString() ?? 'anime',
      defaultContentRating: json['defaultContentRating']?.toString() ?? 'off',
      defaultAnimeWatchTime: (json['defaultAnimeWatchTime'] as num?)?.toInt() ?? 24,
      defaultMangaReadTime: (json['defaultMangaReadTime'] as num?)?.toInt() ?? 15,
      filter18Plus: json['filter18Plus'] == true,
    );
  }

  Map<String, dynamic> _contentToJson(TrackableContent item) {
    if (item is AnimeEntity) {
      return {
        'kind': 'anime',
        'id': item.id,
        'title': item.title,
        'coverImage': item.coverImage,
        'totalEpisodes': item.totalEpisodes,
        'currentEpisode': item.currentEpisode,
        'status': item.status.name,
        'rating': item.rating,
        'genres': item.genres,
        'description': item.description,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      };
    }

    final manga = item as MangaEntity;
    return {
      'kind': 'manga',
      'id': manga.id,
      'title': manga.title,
      'coverImage': manga.coverImage,
      'totalChapters': manga.totalChapters,
      'currentChapter': manga.currentChapter,
      'status': manga.status.name,
      'rating': manga.rating,
      'genres': manga.genres,
      'description': manga.description,
      'isAdult': manga.isAdult,
      'createdAt': manga.createdAt.toIso8601String(),
      'updatedAt': manga.updatedAt.toIso8601String(),
    };
  }

  TrackableContent _contentFromJson(Map<String, dynamic> json) {
    if (json['kind'] == 'anime') {
      return AnimeEntity(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown',
        coverImage: json['coverImage']?.toString() ?? '',
        totalEpisodes: (json['totalEpisodes'] as num?)?.toInt() ?? 0,
        currentEpisode: (json['currentEpisode'] as num?)?.toInt() ?? 0,
        status: AnimeStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => AnimeStatus.watching,
        ),
        rating: (json['rating'] as num?)?.toDouble(),
        genres: (json['genres'] as List? ?? const []).map((item) => item.toString()).toList(),
        description: json['description']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }

    return MangaEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      coverImage: json['coverImage']?.toString() ?? '',
      totalChapters: (json['totalChapters'] as num?)?.toInt() ?? 0,
      currentChapter: (json['currentChapter'] as num?)?.toInt() ?? 0,
      status: MangaStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MangaStatus.reading,
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      genres: (json['genres'] as List? ?? const []).map((item) => item.toString()).toList(),
      description: json['description']?.toString(),
      isAdult: json['isAdult'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _sessionToJson(UserSessionEntity session) {
    return {
      'id': session.id,
      'contentId': session.contentId,
      'contentType': session.contentType.name,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime.toIso8601String(),
      'unitsConsumed': session.unitsConsumed,
    };
  }

  UserSessionEntity _sessionFromJson(Map<String, dynamic> json) {
    return UserSessionEntity(
      id: json['id']?.toString() ?? '',
      contentId: json['contentId']?.toString() ?? '',
      contentType: SessionContentType.values.firstWhere(
        (value) => value.name == json['contentType'],
        orElse: () => SessionContentType.anime,
      ),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      unitsConsumed: (json['unitsConsumed'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime _resolveLastWriteTimestamp(
    UserEntity? profile,
    List<TrackableContent> library,
    RetentionPreferences retentionPreferences,
  ) {
    final dates = <DateTime>[
      if (profile != null) profile.updatedAt,
      ...library.map((item) => item.updatedAt),
      if (retentionPreferences.lastRecommendationRefreshAt != null)
        retentionPreferences.lastRecommendationRefreshAt!,
      if (retentionPreferences.lastAppOpenedAt != null) retentionPreferences.lastAppOpenedAt!,
    ];
    if (dates.isEmpty) return DateTime.now();
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }
}
