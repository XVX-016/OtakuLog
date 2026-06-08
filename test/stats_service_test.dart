import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/stats_service.dart';

void main() {
  late StatsService statsService;

  setUp(() {
    statsService = StatsService();
  });

  group('StatsService', () {
    group('calculateTotalMinutes', () {
      test('should return sum of all session durations', () {
        final now = DateTime.now();
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(minutes: 30)),
            endTime: now,
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(hours: 25)),
            endTime: now.subtract(const Duration(hours: 24, minutes: 30)),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateTotalMinutes(sessions), 60);
      });

      test('should return 0 for empty sessions', () {
        expect(statsService.calculateTotalMinutes([]), 0);
      });
    });

    test('calculateTodayMinutes should only include sessions from today', () {
      final now = DateTime.now();
      final sessions = [
        UserSessionEntity(
          id: '1',
          contentId: 'a1',
          contentType: SessionContentType.anime,
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now,
          unitsConsumed: 1,
        ),
        UserSessionEntity(
          id: '2',
          contentId: 'a1',
          contentType: SessionContentType.anime,
          startTime: now.subtract(const Duration(hours: 25)),
          endTime: now.subtract(const Duration(hours: 24, minutes: 30)),
          unitsConsumed: 1,
        ),
      ];
      expect(statsService.calculateTodayMinutes(sessions), 30);
    });

    group('calculateStreak', () {
      test('should return 0 for empty sessions', () {
        expect(statsService.calculateStreak([]), 0);
      });

      test('should return 1 for a single session today', () {
        final now = DateTime.now();
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(minutes: 30)),
            endTime: now,
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateStreak(sessions), 1);
      });

      test('should return 2 for sessions on consecutive days', () {
        final now = DateTime.now();
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(minutes: 30)),
            endTime: now,
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(hours: 25)),
            endTime: now.subtract(const Duration(hours: 24, minutes: 30)),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateStreak(sessions), 2);
      });

      test('should return 3 for sessions on three consecutive days', () {
        final now = DateTime.now();
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(minutes: 30)),
            endTime: now,
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(hours: 25)),
            endTime: now.subtract(const Duration(hours: 24, minutes: 30)),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '3',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(hours: 49)),
            endTime: now.subtract(const Duration(hours: 48, minutes: 30)),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateStreak(sessions), 3);
      });

      test('should break streak when there is a gap', () {
        final now = DateTime.now();
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(minutes: 30)),
            endTime: now,
            unitsConsumed: 1,
          ),
          // 3 days ago — gap in between
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: now.subtract(const Duration(hours: 73)),
            endTime: now.subtract(const Duration(hours: 72, minutes: 30)),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateStreak(sessions), 1);
      });

      test('should normalize UTC dates from varied session times', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: today.add(const Duration(hours: 23)),
            endTime: today.add(const Duration(hours: 23, minutes: 30)),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: today.subtract(const Duration(hours: 1)),
            endTime: today.subtract(const Duration(minutes: 30)),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateStreak(sessions), 2);
      });
    });

    group('calculateLongestStreak', () {
      test('should return 0 for empty sessions', () {
        expect(statsService.calculateLongestStreak([]), 0);
      });

      test('should return 1 for a single session', () {
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 14, 10, 0),
            endTime: DateTime.utc(2026, 3, 14, 10, 30),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateLongestStreak(sessions), 1);
      });

      test('should return longest streak across consecutive days', () {
        final sessions = [
          // Block 1: 3 consecutive days
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 14, 10, 0),
            endTime: DateTime.utc(2026, 3, 14, 10, 30),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 13, 10, 0),
            endTime: DateTime.utc(2026, 3, 13, 10, 30),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '3',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 12, 10, 0),
            endTime: DateTime.utc(2026, 3, 12, 10, 30),
            unitsConsumed: 1,
          ),
          // Gap: March 11
          // Block 2: 2 consecutive days
          UserSessionEntity(
            id: '4',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 10, 10, 0),
            endTime: DateTime.utc(2026, 3, 10, 10, 30),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '5',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 3, 9, 10, 0),
            endTime: DateTime.utc(2026, 3, 9, 10, 30),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateLongestStreak(sessions), 3);
      });

      test('should handle UTC normalized dates (DST-safe)', () {
        final sessions = [
          UserSessionEntity(
            id: '1',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 11, 2, 10, 0),
            endTime: DateTime.utc(2026, 11, 2, 10, 30),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '2',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 11, 1, 10, 0),
            endTime: DateTime.utc(2026, 11, 1, 10, 30),
            unitsConsumed: 1,
          ),
          UserSessionEntity(
            id: '3',
            contentId: 'a1',
            contentType: SessionContentType.anime,
            startTime: DateTime.utc(2026, 10, 31, 10, 0),
            endTime: DateTime.utc(2026, 10, 31, 10, 30),
            unitsConsumed: 1,
          ),
        ];
        expect(statsService.calculateLongestStreak(sessions), 3);
      });
    });
  });
}
