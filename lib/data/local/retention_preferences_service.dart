import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class RetentionPreferences {
  final bool notificationsEnabled;
  final String? lastAppOpenedAtIso;
  final String? lastRecommendationRefreshAtIso;
  final int lastRecommendationMinutesTotal;
  final int lastRecommendationLibraryCount;
  final String? lastRecommendationLibrarySignature;
  final String? lastWeeklyWrappedPeriodKeyShown;
  final String? lastMonthlyWrappedPeriodKeyShown;
  final int highestUnlockedStreakMilestone;
  final String? lastReminderScheduledForIso;
  final String? lastBackupAtIso;
  final bool preferDataSaverDownloads;
  final List<Map<String, dynamic>> cachedRecommendations;

  // WebDAV preferences (status/non-sensitive only)
  final String? webdavLastSyncedAtIso;
  final String? webdavLastError;

  // Google Drive preferences (status/non-sensitive only)
  final String? googleDriveLastSyncedAtIso;
  final String? googleDriveLastError;

  const RetentionPreferences({
    this.notificationsEnabled = true,
    this.lastAppOpenedAtIso,
    this.lastRecommendationRefreshAtIso,
    this.lastRecommendationMinutesTotal = 0,
    this.lastRecommendationLibraryCount = 0,
    this.lastRecommendationLibrarySignature,
    this.lastWeeklyWrappedPeriodKeyShown,
    this.lastMonthlyWrappedPeriodKeyShown,
    this.highestUnlockedStreakMilestone = 0,
    this.lastReminderScheduledForIso,
    this.lastBackupAtIso,
    this.preferDataSaverDownloads = true,
    this.cachedRecommendations = const [],
    this.webdavLastSyncedAtIso,
    this.webdavLastError,
    this.googleDriveLastSyncedAtIso,
    this.googleDriveLastError,
  });

  DateTime? get lastAppOpenedAt =>
      lastAppOpenedAtIso == null ? null : DateTime.tryParse(lastAppOpenedAtIso!);
  DateTime? get lastRecommendationRefreshAt => lastRecommendationRefreshAtIso == null
      ? null
      : DateTime.tryParse(lastRecommendationRefreshAtIso!);
  DateTime? get lastReminderScheduledFor => lastReminderScheduledForIso == null
      ? null
      : DateTime.tryParse(lastReminderScheduledForIso!);
  DateTime? get lastBackupAt =>
      lastBackupAtIso == null ? null : DateTime.tryParse(lastBackupAtIso!);
  DateTime? get webdavLastSyncedAt =>
      webdavLastSyncedAtIso == null ? null : DateTime.tryParse(webdavLastSyncedAtIso!);
  DateTime? get googleDriveLastSynced =>
      googleDriveLastSyncedAtIso == null ? null : DateTime.tryParse(googleDriveLastSyncedAtIso!);

  RetentionPreferences copyWith({
    bool? notificationsEnabled,
    String? lastAppOpenedAtIso,
    String? lastRecommendationRefreshAtIso,
    int? lastRecommendationMinutesTotal,
    int? lastRecommendationLibraryCount,
    String? lastRecommendationLibrarySignature,
    String? lastWeeklyWrappedPeriodKeyShown,
    String? lastMonthlyWrappedPeriodKeyShown,
    int? highestUnlockedStreakMilestone,
    String? lastReminderScheduledForIso,
    String? lastBackupAtIso,
    bool? preferDataSaverDownloads,
    List<Map<String, dynamic>>? cachedRecommendations,
    String? webdavLastSyncedAtIso,
    String? webdavLastError,
    String? googleDriveLastSyncedAtIso,
    String? googleDriveLastError,
  }) {
    return RetentionPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastAppOpenedAtIso: lastAppOpenedAtIso ?? this.lastAppOpenedAtIso,
      lastRecommendationRefreshAtIso:
          lastRecommendationRefreshAtIso ?? this.lastRecommendationRefreshAtIso,
      lastRecommendationMinutesTotal:
          lastRecommendationMinutesTotal ?? this.lastRecommendationMinutesTotal,
      lastRecommendationLibraryCount:
          lastRecommendationLibraryCount ?? this.lastRecommendationLibraryCount,
      lastRecommendationLibrarySignature:
          lastRecommendationLibrarySignature ?? this.lastRecommendationLibrarySignature,
      lastWeeklyWrappedPeriodKeyShown:
          lastWeeklyWrappedPeriodKeyShown ?? this.lastWeeklyWrappedPeriodKeyShown,
      lastMonthlyWrappedPeriodKeyShown:
          lastMonthlyWrappedPeriodKeyShown ?? this.lastMonthlyWrappedPeriodKeyShown,
      highestUnlockedStreakMilestone:
          highestUnlockedStreakMilestone ?? this.highestUnlockedStreakMilestone,
      lastReminderScheduledForIso:
          lastReminderScheduledForIso ?? this.lastReminderScheduledForIso,
      lastBackupAtIso: lastBackupAtIso ?? this.lastBackupAtIso,
      preferDataSaverDownloads:
          preferDataSaverDownloads ?? this.preferDataSaverDownloads,
      cachedRecommendations: cachedRecommendations ?? this.cachedRecommendations,
      webdavLastSyncedAtIso: webdavLastSyncedAtIso ?? this.webdavLastSyncedAtIso,
      webdavLastError: webdavLastError ?? this.webdavLastError,
      googleDriveLastSyncedAtIso: googleDriveLastSyncedAtIso ?? this.googleDriveLastSyncedAtIso,
      googleDriveLastError: googleDriveLastError ?? this.googleDriveLastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'lastAppOpenedAtIso': lastAppOpenedAtIso,
      'lastRecommendationRefreshAtIso': lastRecommendationRefreshAtIso,
      'lastRecommendationMinutesTotal': lastRecommendationMinutesTotal,
      'lastRecommendationLibraryCount': lastRecommendationLibraryCount,
      'lastRecommendationLibrarySignature': lastRecommendationLibrarySignature,
      'lastWeeklyWrappedPeriodKeyShown': lastWeeklyWrappedPeriodKeyShown,
      'lastMonthlyWrappedPeriodKeyShown': lastMonthlyWrappedPeriodKeyShown,
      'highestUnlockedStreakMilestone': highestUnlockedStreakMilestone,
      'lastReminderScheduledForIso': lastReminderScheduledForIso,
      'lastBackupAtIso': lastBackupAtIso,
      'preferDataSaverDownloads': preferDataSaverDownloads,
      'cachedRecommendations': cachedRecommendations,
      'webdavLastSyncedAtIso': webdavLastSyncedAtIso,
      'webdavLastError': webdavLastError,
      'googleDriveLastSyncedAtIso': googleDriveLastSyncedAtIso,
      'googleDriveLastError': googleDriveLastError,
    };
  }

  factory RetentionPreferences.fromJson(Map<String, dynamic> json) {
    return RetentionPreferences(
      notificationsEnabled: json['notificationsEnabled'] != false,
      lastAppOpenedAtIso: json['lastAppOpenedAtIso']?.toString(),
      lastRecommendationRefreshAtIso: json['lastRecommendationRefreshAtIso']?.toString(),
      lastRecommendationMinutesTotal:
          (json['lastRecommendationMinutesTotal'] as num?)?.toInt() ?? 0,
      lastRecommendationLibraryCount:
          (json['lastRecommendationLibraryCount'] as num?)?.toInt() ?? 0,
      lastRecommendationLibrarySignature: json['lastRecommendationLibrarySignature']?.toString(),
      lastWeeklyWrappedPeriodKeyShown: json['lastWeeklyWrappedPeriodKeyShown']?.toString(),
      lastMonthlyWrappedPeriodKeyShown: json['lastMonthlyWrappedPeriodKeyShown']?.toString(),
      highestUnlockedStreakMilestone:
          (json['highestUnlockedStreakMilestone'] as num?)?.toInt() ?? 0,
      lastReminderScheduledForIso: json['lastReminderScheduledForIso']?.toString(),
      lastBackupAtIso: json['lastBackupAtIso']?.toString(),
      preferDataSaverDownloads: json['preferDataSaverDownloads'] != false,
      cachedRecommendations:
          (json['cachedRecommendations'] as List? ?? const []).whereType<Map>().map((item) {
        return item.map((key, value) => MapEntry(key.toString(), value));
      }).toList(),
      webdavLastSyncedAtIso: json['webdavLastSyncedAtIso']?.toString(),
      webdavLastError: json['webdavLastError']?.toString(),
      googleDriveLastSyncedAtIso: json['googleDriveLastSyncedAtIso']?.toString(),
      googleDriveLastError: json['googleDriveLastError']?.toString(),
    );
  }
}

class RetentionPreferencesService {
  static const String _fileName = 'retention_preferences.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<RetentionPreferences> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const RetentionPreferences();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const RetentionPreferences();
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return const RetentionPreferences();
      }
      return RetentionPreferences.fromJson(json);
    } catch (_) {
      return const RetentionPreferences();
    }
  }

  Future<RetentionPreferences> save(RetentionPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
    return preferences;
  }
}
