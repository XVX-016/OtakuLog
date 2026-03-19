import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/stats_service.dart';

void main() {
  late StatsService statsService;

  setUp(() {
    statsService = StatsService();
  });

  group('StatsService Tests', () {
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

    test('calculateTotalMinutes should return sum of all session durations', () {
      expect(statsService.calculateTotalMinutes(sessions), 60);
    });

    test('calculateTodayMinutes should only include sessions from today', () {
      expect(statsService.calculateTodayMinutes(sessions), 30);
    });

    test('calculateStreak should return 2 for consecutive days', () {
      expect(statsService.calculateStreak(sessions), 2);
    });
  });
}
