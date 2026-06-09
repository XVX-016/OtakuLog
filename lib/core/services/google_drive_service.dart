import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/data/mappers/activity_mapper.dart';
import 'package:otakulog/data/models/daily_activity.dart';
import 'package:otakulog/domain/entities/activity.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/repositories/anime_repository.dart';
import 'package:otakulog/domain/repositories/manga_repository.dart';
import 'package:otakulog/domain/repositories/session_repository.dart';
import 'package:otakulog/domain/repositories/user_repository.dart';
import 'package:otakulog/data/remote/backup_mapper.dart';
import 'package:otakulog/core/services/sync_service.dart';
import 'package:otakulog/features/cloud/models/backup_payload.dart';
import 'google_auth_client.dart';

class GoogleDriveSyncService {
  final UserRepository userRepository;
  final AnimeRepository animeRepository;
  final MangaRepository mangaRepository;
  final SessionRepository sessionRepository;
  final RetentionPreferencesService retentionPreferencesService;
  final BackupMapper backupMapper;
  final SyncService syncService;
  final Isar isar;

  late final GoogleSignIn _googleSignIn;

  GoogleDriveSyncService({
    required this.userRepository,
    required this.animeRepository,
    required this.mangaRepository,
    required this.sessionRepository,
    required this.retentionPreferencesService,
    required this.backupMapper,
    required this.syncService,
    required this.isar,
  }) {
    final clientId = dotenv.maybeGet('GOOGLE_CLIENT_ID');
    _googleSignIn = GoogleSignIn(
      clientId: (clientId == null || clientId.trim().isEmpty) ? null : clientId.trim(),
      scopes: [
        'email',
        'https://www.googleapis.com/auth/drive.appdata',
      ],
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Google Sign-Out failed: $e');
    }
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  Future<String?> getUserEmail() async {
    final account = _googleSignIn.currentUser ?? await signInSilently();
    return account?.email;
  }

  Future<void> syncNow({required RestoreMode mode}) async {
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    if (account == null) {
      account = await signInSilently();
    }
    if (account == null) {
      throw Exception('User is not signed in to Google.');
    }

    try {
      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);

      // Query if backup file exists in the appDataFolder
      final fileList = await driveApi.files.list(
        q: "name = 'otakulog_backup.json'",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, modifiedTime)',
      );

      String? remoteFileId;
      bool remoteFileExists = false;

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final file = fileList.files!.first;
        remoteFileId = file.id;
        remoteFileExists = true;

        // Download existing backup
        final drive.Media media = await driveApi.files.get(
          remoteFileId!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ) as drive.Media;

        final List<int> bytes = [];
        await for (final chunk in media.stream) {
          bytes.addAll(chunk);
        }

        final content = utf8.decode(bytes);
        if (content.trim().isNotEmpty) {
          Map<String, dynamic> json;
          try {
            json = jsonDecode(content) as Map<String, dynamic>;
          } catch (e) {
            throw const FormatException('The remote backup file is not valid JSON.');
          }

          if (!json.containsKey('schemaVersion') || !json.containsKey('exportedAt')) {
            throw const FormatException('The remote backup file is missing required metadata.');
          }

          final payload = BackupPayload.fromJson(json);
          if (payload.schemaVersion > BackupPayload.currentSchemaVersion) {
            throw FormatException(
              'The remote backup was created by a newer version of the app (schema v${payload.schemaVersion}). '
              'Please update the app before syncing.',
            );
          }

          await syncService.mergeData(payload, mode: mode);
        }
      }

      // Gather current local database data to upload
      final profile = await userRepository.getUser('local_user');
      final animeList = await animeRepository.getAllAnime();
      final mangaList = await mangaRepository.getAllManga();
      final library = [...animeList, ...mangaList];
      final sessions = await sessionRepository.getAllSessions();
      final streaks = (await isar.dailyActivitys.where().findAll())
          .map(ActivityMapper.toEntity)
          .toList();
      final currentPrefs = await retentionPreferencesService.load();

      final updatedPayload = backupMapper.exportPayload(
        profile: profile,
        library: library,
        sessions: sessions,
        streaks: streaks,
        retentionPreferences: currentPrefs,
      );

      final jsonString = jsonEncode(updatedPayload.toJson());
      final mediaStream = Stream.value(utf8.encode(jsonString));
      final uploadMedia = drive.Media(
        mediaStream,
        jsonString.length,
        contentType: 'application/json',
      );

      if (remoteFileExists && remoteFileId != null) {
        // Update existing file
        final driveFile = drive.File();
        await driveApi.files.update(
          driveFile,
          remoteFileId,
          uploadMedia: uploadMedia,
        );
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = 'otakulog_backup.json'
          ..parents = ['appDataFolder'];
        await driveApi.files.create(
          driveFile,
          uploadMedia: uploadMedia,
        );
      }

      // Update retention preferences state
      final finalPrefs = await retentionPreferencesService.load();
      await retentionPreferencesService.save(
        finalPrefs.copyWith(
          googleDriveLastSyncedAtIso: DateTime.now().toIso8601String(),
          googleDriveLastError: '',
        ),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final finalPrefs = await retentionPreferencesService.load();
      await retentionPreferencesService.save(
        finalPrefs.copyWith(
          googleDriveLastError: errorMsg,
        ),
      );
      rethrow;
    }
  }
}
