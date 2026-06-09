import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';

void main() {
  group('Google Drive Status & Preference Serialization Tests', () {
    test('RetentionPreferences should successfully serialize and deserialize Google Drive status fields', () {
      const preferences = RetentionPreferences(
        notificationsEnabled: false,
        googleDriveLastSyncedAtIso: '2026-06-07T12:00:00.000Z',
        googleDriveLastError: 'Connection Timeout',
      );

      final json = preferences.toJson();
      
      expect(json['googleDriveLastSyncedAtIso'], '2026-06-07T12:00:00.000Z');
      expect(json['googleDriveLastError'], 'Connection Timeout');

      final deserialized = RetentionPreferences.fromJson(json);

      expect(deserialized.googleDriveLastSyncedAtIso, '2026-06-07T12:00:00.000Z');
      expect(deserialized.googleDriveLastError, 'Connection Timeout');
      expect(deserialized.googleDriveLastSynced, isNotNull);
      expect(deserialized.googleDriveLastSynced!.year, 2026);
    });

    test('RetentionPreferences copyWith should cleanly update Google Drive status fields', () {
      const preferences = RetentionPreferences();
      
      final updated = preferences.copyWith(
        googleDriveLastSyncedAtIso: '2026-06-07T22:00:00.000Z',
        googleDriveLastError: '',
      );

      expect(updated.googleDriveLastSyncedAtIso, '2026-06-07T22:00:00.000Z');
      expect(updated.googleDriveLastError, isEmpty);
    });
  });
}
