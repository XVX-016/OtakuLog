import 'dart:io';

import 'package:goon_tracker/data/local/retention_preferences_service.dart';
import 'package:goon_tracker/data/mappers/anime_mapper.dart';
import 'package:goon_tracker/data/mappers/manga_mapper.dart';
import 'package:goon_tracker/data/mappers/user_mapper.dart';
import 'package:goon_tracker/data/mappers/user_session_mapper.dart';
import 'package:goon_tracker/data/models/anime_model.dart';
import 'package:goon_tracker/data/models/manga_model.dart';
import 'package:goon_tracker/data/models/user_model.dart';
import 'package:goon_tracker/data/models/user_session_model.dart';
import 'package:goon_tracker/data/remote/backup_mapper.dart';
import 'package:goon_tracker/data/remote/backup_service.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/features/cloud/models/backup_payload.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final BackupService backupService;
  final BackupMapper backupMapper;
  final RetentionPreferencesService retentionPreferencesService;
  final Isar isar;

  SyncService({
    required this.backupService,
    required this.backupMapper,
    required this.retentionPreferencesService,
    required this.isar,
  });

  Future<RemoteBackupRecord?> previewRemoteBackup() async {
    return backupService.fetchBackup();
  }

  Future<SyncResult> pushLocalToRemote({
    required UserEntity? profile,
    required List<TrackableContent> library,
    required List<UserSessionEntity> sessions,
  }) async {
    try {
      final preferences = await retentionPreferencesService.load();
      final payload = backupMapper.exportPayload(
        profile: profile,
        library: library,
        sessions: sessions,
        retentionPreferences: preferences,
      );
      await backupService.uploadBackup(payload);
      await retentionPreferencesService.save(
        preferences.copyWith(lastBackupAtIso: DateTime.now().toIso8601String()),
      );
      return const SyncResult(success: true, message: 'Backup complete');
    } on AuthException catch (error) {
      return SyncResult(success: false, message: error.message);
    } on SocketException {
      return const SyncResult(success: false, message: 'No internet connection');
    } catch (error) {
      return SyncResult(success: false, message: error.toString());
    }
  }

  Future<SyncResult> pullRemoteToLocal({required RestoreMode mode}) async {
    try {
      final remote = await backupService.fetchBackup();
      if (remote == null) {
        return const SyncResult(success: false, message: 'No backup found');
      }
      if (remote.payload.schemaVersion > BackupPayload.currentSchemaVersion) {
        return const SyncResult(
          success: false,
          message: 'This backup was created by a newer app version.',
        );
      }

      await mergeData(remote.payload, mode: mode);
      final preferences = await retentionPreferencesService.load();
      await retentionPreferencesService.save(
        preferences.copyWith(lastBackupAtIso: remote.updatedAt.toIso8601String()),
      );
      return const SyncResult(success: true, message: 'Restore complete');
    } on AuthException catch (error) {
      return SyncResult(success: false, message: error.message);
    } on SocketException {
      return const SyncResult(success: false, message: 'No internet connection');
    } catch (error) {
      return SyncResult(success: false, message: error.toString());
    }
  }

  Future<void> mergeData(
    BackupPayload remotePayload, {
    required RestoreMode mode,
  }) async {
    final remoteProfile = backupMapper.profileFromPayload(remotePayload);
    final remoteLibrary = backupMapper.libraryFromPayload(remotePayload);
    final remoteSessions = backupMapper.sessionsFromPayload(remotePayload);
    final remotePreferences = backupMapper.retentionPreferencesFromPayload(remotePayload);

    if (mode == RestoreMode.replaceLocal) {
      await _replaceLocal(
        profile: remoteProfile,
        library: remoteLibrary,
        sessions: remoteSessions,
        retentionPreferences: remotePreferences,
      );
      return;
    }

    final localProfile = await _loadLocalProfile();
    final localLibrary = await _loadLocalLibrary();
    final localSessions = await _loadLocalSessions();
    final localPreferences = await retentionPreferencesService.load();

    final mergedProfile = _mergeProfile(localProfile, remoteProfile);
    final mergedLibrary = _mergeLibrary(localLibrary, remoteLibrary);
    final mergedSessions = _mergeSessions(localSessions, remoteSessions);
    final mergedPreferences = _mergePreferences(localPreferences, remotePreferences);

    await _replaceLocal(
      profile: mergedProfile,
      library: mergedLibrary,
      sessions: mergedSessions,
      retentionPreferences: mergedPreferences,
    );
  }

  Future<void> _replaceLocal({
    required UserEntity? profile,
    required List<TrackableContent> library,
    required List<UserSessionEntity> sessions,
    required RetentionPreferences retentionPreferences,
  }) async {
    await isar.writeTxn(() async {
      await isar.animeModels.clear();
      await isar.mangaModels.clear();
      await isar.userSessionModels.clear();
      await isar.userModels.clear();

      if (profile != null) {
        await isar.userModels.put(UserMapper.toModel(profile));
      }

      final animeModels = library.whereType<AnimeEntity>().map(AnimeMapper.toModel).toList();
      final mangaModels = library.whereType<MangaEntity>().map(MangaMapper.toModel).toList();
      final sessionModels = sessions.map(UserSessionMapper.toModel).toList();

      if (animeModels.isNotEmpty) {
        await isar.animeModels.putAll(animeModels);
      }
      if (mangaModels.isNotEmpty) {
        await isar.mangaModels.putAll(mangaModels);
      }
      if (sessionModels.isNotEmpty) {
        await isar.userSessionModels.putAll(sessionModels);
      }
    });

    await retentionPreferencesService.save(retentionPreferences);
  }

  Future<UserEntity?> _loadLocalProfile() async {
    final model = await isar.userModels.where().findFirst();
    return model == null ? null : UserMapper.toEntity(model);
  }

  Future<List<TrackableContent>> _loadLocalLibrary() async {
    final anime = (await isar.animeModels.where().findAll()).map(AnimeMapper.toEntity);
    final manga = (await isar.mangaModels.where().findAll()).map(MangaMapper.toEntity);
    return [...anime, ...manga];
  }

  Future<List<UserSessionEntity>> _loadLocalSessions() async {
    final models = await isar.userSessionModels.where().findAll();
    return models.map(UserSessionMapper.toEntity).toList();
  }

  UserEntity? _mergeProfile(UserEntity? local, UserEntity? remote) {
    if (local == null) return remote;
    if (remote == null) return local;
    return local.updatedAt.isAfter(remote.updatedAt) ? local : remote;
  }

  List<TrackableContent> _mergeLibrary(
    List<TrackableContent> local,
    List<TrackableContent> remote,
  ) {
    final merged = <String, TrackableContent>{
      for (final item in local) item.id: item,
    };

    for (final remoteItem in remote) {
      final localItem = merged[remoteItem.id];
      if (localItem == null) {
        merged[remoteItem.id] = remoteItem;
        continue;
      }
      merged[remoteItem.id] = _mergeTrackable(localItem, remoteItem);
    }

    return merged.values.toList();
  }

  TrackableContent _mergeTrackable(TrackableContent local, TrackableContent remote) {
    if (local is AnimeEntity && remote is AnimeEntity) {
      final localCompleted = local.status == AnimeStatus.completed;
      final remoteCompleted = remote.status == AnimeStatus.completed;
      final winner = _shouldUseRemote(
        localCompleted: localCompleted,
        remoteCompleted: remoteCompleted,
        localProgress: local.currentEpisode,
        remoteProgress: remote.currentEpisode,
        localUpdatedAt: local.updatedAt,
        remoteUpdatedAt: remote.updatedAt,
      )
          ? remote
          : local;
      final latestNonNullRating =
          remote.rating != null && remote.updatedAt.isAfter(local.updatedAt) ? remote.rating : local.rating ?? remote.rating;
      return winner.copyWith(rating: latestNonNullRating, updatedAt: winner.updatedAt);
    }

    if (local is MangaEntity && remote is MangaEntity) {
      final localCompleted = local.status == MangaStatus.completed;
      final remoteCompleted = remote.status == MangaStatus.completed;
      final winner = _shouldUseRemote(
        localCompleted: localCompleted,
        remoteCompleted: remoteCompleted,
        localProgress: local.currentChapter,
        remoteProgress: remote.currentChapter,
        localUpdatedAt: local.updatedAt,
        remoteUpdatedAt: remote.updatedAt,
      )
          ? remote
          : local;
      final latestNonNullRating =
          remote.rating != null && remote.updatedAt.isAfter(local.updatedAt) ? remote.rating : local.rating ?? remote.rating;
      return winner.copyWith(rating: latestNonNullRating, updatedAt: winner.updatedAt);
    }

    return remote;
  }

  bool _shouldUseRemote({
    required bool localCompleted,
    required bool remoteCompleted,
    required int localProgress,
    required int remoteProgress,
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) {
    if (remoteCompleted && !localCompleted) return true;
    if (localCompleted && !remoteCompleted) return false;
    if (remoteProgress > localProgress) return true;
    if (localProgress > remoteProgress) return false;
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  List<UserSessionEntity> _mergeSessions(
    List<UserSessionEntity> local,
    List<UserSessionEntity> remote,
  ) {
    final merged = <String, UserSessionEntity>{
      for (final session in local) session.id: session,
    };

    for (final session in remote) {
      final existing = merged[session.id];
      if (existing == null || session.endTime.isAfter(existing.endTime)) {
        merged[session.id] = session;
      }
    }
    return merged.values.toList();
  }

  RetentionPreferences _mergePreferences(
    RetentionPreferences local,
    RetentionPreferences remote,
  ) {
    final localUpdated = local.lastAppOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remoteUpdated = remote.lastAppOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (remoteUpdated.isAfter(localUpdated)) {
      return remote;
    }
    return local.copyWith(lastBackupAtIso: remote.lastBackupAtIso ?? local.lastBackupAtIso);
  }
}
