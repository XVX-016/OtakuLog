class BackupPayload {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime exportedAt;
  final DateTime lastWriteTimestamp;
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> library;
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? retentionPreferences;

  const BackupPayload({
    this.schemaVersion = currentSchemaVersion,
    required this.exportedAt,
    required this.lastWriteTimestamp,
    required this.profile,
    required this.library,
    required this.sessions,
    required this.retentionPreferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'lastWriteTimestamp': lastWriteTimestamp.toIso8601String(),
      'profile': profile,
      'library': library,
      'sessions': sessions,
      'retentionPreferences': retentionPreferences,
    };
  }

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      exportedAt: DateTime.tryParse(json['exportedAt']?.toString() ?? '') ?? DateTime.now(),
      lastWriteTimestamp:
          DateTime.tryParse(json['lastWriteTimestamp']?.toString() ?? '') ?? DateTime.now(),
      profile: (json['profile'] as Map?)?.cast<String, dynamic>(),
      library: (json['library'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(),
      sessions: (json['sessions'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(),
      retentionPreferences: (json['retentionPreferences'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

enum RestoreMode { merge, replaceLocal }

class SyncResult {
  final bool success;
  final String message;

  const SyncResult({
    required this.success,
    required this.message,
  });
}
