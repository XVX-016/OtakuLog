import 'package:otakulog/features/cloud/models/backup_payload.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteBackupRecord {
  final BackupPayload payload;
  final DateTime updatedAt;

  const RemoteBackupRecord({
    required this.payload,
    required this.updatedAt,
  });
}

class BackupService {
  static const String tableName = 'user_backup';

  final SupabaseClient? _client;

  BackupService({SupabaseClient? client}) : _client = client;

  bool get isAvailable => _client != null;

  Future<void> uploadBackup(BackupPayload payload) async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to sign in before backing up.');
    }

    await client.from(tableName).upsert({
      'user_id': user.id,
      'payload_json': payload.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<RemoteBackupRecord?> fetchBackup() async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to sign in before restoring data.');
    }

    final rows = await client
        .from(tableName)
        .select('payload_json, updated_at')
        .eq('user_id', user.id)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return RemoteBackupRecord(
      payload: BackupPayload.fromJson((row['payload_json'] as Map).cast<String, dynamic>()),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Cloud is not configured for this build.');
    }
    return client;
  }
}
