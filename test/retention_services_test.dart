import 'package:flutter_test/flutter_test.dart';
import 'package:otakulog/core/services/wrapped_trigger_service.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/recommendation_service.dart';

void main() {
  final service = RecommendationService();

  List<TrackableContent> library() {
    return [
      AnimeEntity(
        id: 'a1',
        title: 'Attack',
        coverImage: '',
        totalEpisodes: 12,
        currentEpisode: 12,
        status: AnimeStatus.completed,
        genres: const ['Action', 'Fantasy'],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      ),
      MangaEntity(
        id: 'm1',
        title: 'Bloom',
        coverImage: '',
        totalChapters: 40,
        currentChapter: 12,
        status: MangaStatus.reading,
        genres: const ['Romance', 'Drama'],
        isAdult: false,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 3),
      ),
    ];
  }

  List<UserSessionEntity> sessions() {
    final now = DateTime.now();
    return [
      UserSessionEntity(
        id: '1',
        contentId: 'a1',
        contentType: SessionContentType.anime,
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 3)),
        unitsConsumed: 2,
      ),
      UserSessionEntity(
        id: '2',
        contentId: 'm1',
        contentType: SessionContentType.manga,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 20)),
        unitsConsumed: 3,
      ),
    ];
  }

  test('profile weighting favors completed items and time spent', () {
    final profile = service.buildProfile(sessions(), library(), currentStreak: 4);
    expect(profile.topGenres.keys.first, anyOf('Action', 'Fantasy', 'Romance', 'Drama'));
    expect(profile.currentStreak, 4);
    expect(profile.avgSessionLength, greaterThan(0));
    expect(profile.signalStrength, greaterThan(0));
  });

  test('recommendation refresh threshold respects minutes and library size', () {
    final now = DateTime(2026, 3, 17, 18);
    expect(
      service.shouldRefreshRecommendations(
        now: now,
        lastRefreshAt: now.subtract(const Duration(hours: 1)),
        totalMinutes: 120,
        lastRefreshMinutesTotal: 95,
        libraryCount: 10,
        lastRefreshLibraryCount: 10,
        librarySignature: 'sig-a',
        lastRefreshLibrarySignature: 'sig-a',
      ),
      isFalse,
    );
    expect(
      service.shouldRefreshRecommendations(
        now: now,
        lastRefreshAt: now.subtract(const Duration(hours: 1)),
        totalMinutes: 130,
        lastRefreshMinutesTotal: 95,
        libraryCount: 10,
        lastRefreshLibraryCount: 10,
        librarySignature: 'sig-a',
        lastRefreshLibrarySignature: 'sig-a',
      ),
      isTrue,
    );
  });

  test('wrapped trigger compares period keys instead of timestamps', () {
    final triggerService = WrappedTriggerService();
    final decision = triggerService.evaluate(
      preferences: const RetentionPreferences(
        lastWeeklyWrappedPeriodKeyShown: '2026-W10',
        lastMonthlyWrappedPeriodKeyShown: '2026-02',
      ),
      hasWeeklyData: true,
      hasMonthlyData: true,
      now: DateTime(2026, 3, 17),
    );
    expect(decision.showWeekly, isTrue);
    expect(decision.showMonthly, isTrue);

    final samePeriod = triggerService.evaluate(
      preferences: RetentionPreferences(
        lastWeeklyWrappedPeriodKeyShown: triggerService.weeklyPeriodKey(DateTime(2026, 3, 17)),
        lastMonthlyWrappedPeriodKeyShown: triggerService.monthlyPeriodKey(DateTime(2026, 3, 17)),
      ),
      hasWeeklyData: true,
      hasMonthlyData: true,
      now: DateTime(2026, 3, 17),
    );
    expect(samePeriod.hasAny, isFalse);
  });
}
