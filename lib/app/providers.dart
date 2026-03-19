import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/data/local/isar_service.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/data/remote/auth_service.dart';
import 'package:otakulog/data/remote/backup_mapper.dart';
import 'package:otakulog/data/remote/backup_service.dart';
import 'package:otakulog/data/remote/anilist_service.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/data/remote/nhentai_service.dart';
import 'package:otakulog/data/repositories/anime_repository_impl.dart';
import 'package:otakulog/data/repositories/isar_tracker_repository.dart';
import 'package:otakulog/data/repositories/manga_repository_impl.dart';
import 'package:otakulog/data/repositories/search_repository_impl.dart';
import 'package:otakulog/data/repositories/session_repository_impl.dart';
import 'package:otakulog/data/repositories/user_repository_impl.dart';
import 'package:otakulog/core/analytics/local_analytics_service.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/repositories/anime_repository.dart';
import 'package:otakulog/domain/repositories/manga_repository.dart';
import 'package:otakulog/domain/repositories/search_repository.dart';
import 'package:otakulog/domain/repositories/session_repository.dart';
import 'package:otakulog/domain/repositories/tracker_repository.dart';
import 'package:otakulog/domain/repositories/user_repository.dart';
import 'package:otakulog/domain/services/recommendation_service.dart';
import 'package:otakulog/domain/services/stats_service.dart';
import 'package:otakulog/core/config/cloud_config.dart';
import 'package:otakulog/core/config/cloud_runtime.dart';
import 'package:otakulog/core/services/reminder_service.dart';
import 'package:otakulog/core/services/sync_service.dart';
import 'package:otakulog/core/services/wrapped_trigger_service.dart';
import 'package:otakulog/features/activity_models.dart';
import 'package:otakulog/features/cloud/models/cloud_availability_state.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';
import 'package:otakulog/features/stats/models/wrapped_summary.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services
final anilistServiceProvider =
    Provider<AnilistService>((ref) => AnilistService());
final mangadexServiceProvider =
    Provider<MangadexService>((ref) => MangadexService());
final nhentaiServiceProvider =
    Provider<NhentaiService>((ref) => NhentaiService());
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());
final recommendationServiceProvider =
    Provider<RecommendationService>((ref) => RecommendationService());
final retentionPreferencesServiceProvider =
    Provider<RetentionPreferencesService>(
        (ref) => RetentionPreferencesService());
final wrappedTriggerServiceProvider =
    Provider<WrappedTriggerService>((ref) => WrappedTriggerService());
final reminderServiceProvider =
    Provider<ReminderService>((ref) => ReminderService());
final localAnalyticsServiceProvider =
    Provider<LocalAnalyticsService>((ref) => LocalAnalyticsService());
final backupMapperProvider = Provider<BackupMapper>((ref) => BackupMapper());
final cloudConfigProvider =
    Provider<CloudConfig>((ref) => CloudConfig.fromEnv());
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!CloudRuntime.isConfigured) return null;
  return Supabase.instance.client;
});
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(client: ref.watch(supabaseClientProvider));
});
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(client: ref.watch(supabaseClientProvider));
});
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    backupService: ref.watch(backupServiceProvider),
    backupMapper: ref.watch(backupMapperProvider),
    retentionPreferencesService: ref.watch(retentionPreferencesServiceProvider),
    isar: IsarService.instance,
  );
});
final cloudDegradedProvider = StateProvider<bool>((ref) => false);

// Repositories
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepositoryImpl(IsarService.instance);
});

final mangaRepositoryProvider = Provider<MangaRepository>((ref) {
  return MangaRepositoryImpl(IsarService.instance);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(IsarService.instance);
});

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  return IsarTrackerRepository(IsarService.instance);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(IsarService.instance);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final anilist = ref.watch(anilistServiceProvider);
  final mangadex = ref.watch(mangadexServiceProvider);
  final nhentai = ref.watch(nhentaiServiceProvider);
  return SearchRepositoryImpl(
    anilistService: anilist,
    mangadexService: mangadex,
    nhentaiService: nhentai,
  );
});

// Domain Providers
final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  return ref.watch(userRepositoryProvider).getUser('local_user');
});

final retentionPreferencesProvider =
    FutureProvider<RetentionPreferences>((ref) {
  return ref.watch(retentionPreferencesServiceProvider).load();
});

final analyticsSnapshotProvider = FutureProvider<AnalyticsSnapshot>((ref) {
  return ref.watch(localAnalyticsServiceProvider).load();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  final service = ref.watch(authServiceProvider);
  if (!service.isAvailable) {
    return Stream<Session?>.value(null);
  }
  return (() async* {
    yield service.getCurrentSession();
    yield* service.authStateChanges().map((state) => state.session);
  })();
});

final authUserProvider = Provider<User?>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return session?.user;
});

final cloudAvailabilityProvider = Provider<CloudAvailabilityState>((ref) {
  final config = ref.watch(cloudConfigProvider);
  if (!config.isValid || !CloudRuntime.isConfigured) {
    return CloudAvailabilityState.disabledMissingConfig;
  }
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    return CloudAvailabilityState.signedOut;
  }
  if (ref.watch(cloudDegradedProvider)) {
    return CloudAvailabilityState.degradedOffline;
  }
  return CloudAvailabilityState.ready;
});

final remoteBackupPreviewProvider = FutureProvider<BackupPreview?>((ref) async {
  final availability = ref.watch(cloudAvailabilityProvider);
  if (availability != CloudAvailabilityState.ready &&
      availability != CloudAvailabilityState.degradedOffline) {
    return null;
  }
  final remote = await ref.watch(syncServiceProvider).previewRemoteBackup();
  if (remote == null) return null;
  return ref.watch(backupMapperProvider).buildPreview(remote.payload);
});

final trendingAnimeProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref
      .watch(searchRepositoryProvider)
      .getTrendingAnime(
        page: 1,
        perPage: 10,
        filters: const SearchFilters(medium: SearchMedium.anime),
      )
      .then((results) => results.map((result) => result.content).toList());
});

final trendingMangaProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref
      .watch(searchRepositoryProvider)
      .getTrendingManga(
        page: 1,
        perPage: 10,
        filters: const SearchFilters(medium: SearchMedium.manga),
      )
      .then((results) => results.map((result) => result.content).toList());
});

final recentSessionsProvider = FutureProvider<List<UserSessionEntity>>((ref) {
  return ref.watch(sessionRepositoryProvider).getRecentSessions();
});

final allSessionsProvider = FutureProvider<List<UserSessionEntity>>((ref) {
  return ref.watch(sessionRepositoryProvider).getAllSessions();
});

final dailyActivityProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  return ref.watch(statsServiceProvider).calculateDailyTotals(
        sessions,
        days: 120,
      );
});

final monthlyActivityProvider =
    FutureProvider.family<Map<DateTime, int>, DateTime>((ref, month) async {
  final normalizedMonth = DateTime(month.year, month.month);
  final activity = await ref
      .watch(trackerRepositoryProvider)
      .getActivityByMonth(normalizedMonth.year, normalizedMonth.month);
  return {
    for (final day in activity)
      DateTime(day.date.year, day.date.month, day.date.day): day.totalMinutes,
  };
});

final earliestActivityDateProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(trackerRepositoryProvider).getEarliestActivityDate();
});

final libraryAnimeProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(animeRepositoryProvider).getAllAnime();
});

final libraryMangaProvider = FutureProvider<List<TrackableContent>>((ref) {
  return ref.watch(mangaRepositoryProvider).getAllManga();
});

final animeByIdProvider = FutureProvider.family((ref, String id) {
  return ref.watch(animeRepositoryProvider).getAnimeById(id);
});

final mangaByIdProvider = FutureProvider.family((ref, String id) {
  return ref.watch(mangaRepositoryProvider).getMangaById(id);
});

final combinedLibraryProvider =
    FutureProvider<List<TrackableContent>>((ref) async {
  final anime = await ref.watch(libraryAnimeProvider.future);
  final manga = await ref.watch(libraryMangaProvider.future);
  final combined = [...anime, ...manga];
  combined.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return combined;
});

final latestSessionByContentProvider =
    FutureProvider<Map<String, DateTime>>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final map = <String, DateTime>{};
  for (final session in sessions) {
    final current = map[session.contentId];
    if (current == null || session.endTime.isAfter(current)) {
      map[session.contentId] = session.endTime;
    }
  }
  return map;
});

final activityTimelineProvider =
    FutureProvider<List<ActivityItem>>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  final titleById = {
    for (final item in library) item.id: item.title,
  };

  final items = sessions
      .map(
        (session) => ActivityItem.fromSession(
          session,
          title: titleById[session.contentId] ?? 'Unknown title',
        ),
      )
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return items;
});

final userPreferenceProfileProvider =
    FutureProvider<UserPreferenceProfile>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  final stats = ref.watch(statsServiceProvider);
  return ref.watch(recommendationServiceProvider).buildProfile(
        sessions,
        library,
        currentStreak: stats.calculateStreak(sessions),
      );
});

final searchDefaultsProvider = FutureProvider<SearchFilters>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final medium = user?.defaultSearchMedium == 'manga'
      ? SearchMedium.manga
      : SearchMedium.anime;
  final adultMode = switch (user?.defaultAdultMode) {
    'mixed' => AdultMode.mixed,
    'explicitOnly' => AdultMode.explicitOnly,
    _ => AdultMode.off,
  };
  return SearchFilters(medium: medium, adultMode: adultMode);
});

final recommendationsProvider =
    FutureProvider<List<PersonalizedRecommendation>>((ref) async {
  final preferencesService = ref.watch(retentionPreferencesServiceProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  final repository = ref.watch(searchRepositoryProvider);
  final preferences = await ref.watch(retentionPreferencesProvider.future);
  final profile = await ref.watch(userPreferenceProfileProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  final sessions = await ref.watch(allSessionsProvider.future);
  final totalMinutes =
      ref.watch(statsServiceProvider).calculateTotalMinutes(sessions);
  final librarySignature = _librarySignature(library);
  final now = DateTime.now();

  final shouldRefresh = recommendationService.shouldRefreshRecommendations(
    now: now,
    lastRefreshAt: preferences.lastRecommendationRefreshAt,
    totalMinutes: totalMinutes,
    lastRefreshMinutesTotal: preferences.lastRecommendationMinutesTotal,
    libraryCount: library.length,
    lastRefreshLibraryCount: preferences.lastRecommendationLibraryCount,
    librarySignature: librarySignature,
    lastRefreshLibrarySignature: preferences.lastRecommendationLibrarySignature,
  );

  if (!shouldRefresh && preferences.cachedRecommendations.isNotEmpty) {
    return preferences.cachedRecommendations
        .map(PersonalizedRecommendation.fromJson)
        .toList();
  }

  final candidates = await _fetchRecommendationCandidates(repository, profile);
  final recommendations = recommendationService.buildRecommendations(
    profile: profile,
    library: library,
    candidates: candidates,
  );

  final persisted = preferences.copyWith(
    lastRecommendationRefreshAtIso: now.toIso8601String(),
    lastRecommendationMinutesTotal: totalMinutes,
    lastRecommendationLibraryCount: library.length,
    lastRecommendationLibrarySignature: librarySignature,
    cachedRecommendations:
        recommendations.map((item) => item.toJson()).toList(),
  );
  await preferencesService.save(persisted);
  ref.invalidate(retentionPreferencesProvider);
  return recommendations;
});

final weeklyWrappedProvider = FutureProvider<WrappedSummary>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  return ref
      .watch(statsServiceProvider)
      .generateWeeklyWrapped(sessions, library);
});

final monthlyWrappedProvider = FutureProvider<WrappedSummary>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  return ref
      .watch(statsServiceProvider)
      .generateMonthlyWrapped(sessions, library);
});

final wrappedPromptProvider = FutureProvider<WrappedSummary?>((ref) async {
  final preferences = await ref.watch(retentionPreferencesProvider.future);
  final weekly = await ref.watch(weeklyWrappedProvider.future);
  final monthly = await ref.watch(monthlyWrappedProvider.future);
  final decision = ref.watch(wrappedTriggerServiceProvider).evaluate(
        preferences: preferences,
        hasWeeklyData: weekly.totalMinutes > 0,
        hasMonthlyData: monthly.totalMinutes > 0,
      );

  if (decision.showMonthly) return monthly;
  if (decision.showWeekly) return weekly;
  return null;
});

final retentionReminderProvider =
    FutureProvider<RetentionReminder>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final library = await ref.watch(combinedLibraryProvider.future);
  final profile = await ref.watch(userPreferenceProfileProvider.future);
  final preferences = await ref.watch(retentionPreferencesProvider.future);
  return ref.watch(recommendationServiceProvider).buildReminder(
        sessions: sessions,
        library: library,
        profile: profile,
        remindersEnabled: preferences.notificationsEnabled,
        lastAppOpenedAt: preferences.lastAppOpenedAt,
      );
});

Future<List<SearchResultItem>> _fetchRecommendationCandidates(
  SearchRepository repository,
  UserPreferenceProfile profile,
) async {
  if (!profile.hasStrongSignal) {
    final fallbackAnime = await repository.getTrendingAnime(
      page: 1,
      perPage: 12,
      filters: const SearchFilters(
          medium: SearchMedium.anime, sort: SearchSort.trending),
    );
    final fallbackManga = await repository.getTrendingManga(
      page: 1,
      perPage: 12,
      filters: const SearchFilters(
          medium: SearchMedium.manga, sort: SearchSort.popular),
    );
    return {
      for (final item in [...fallbackAnime, ...fallbackManga]) item.id: item,
    }.values.toList();
  }

  final genres = profile.topGenres.keys.take(2).toList();
  final candidateBuckets = <List<SearchResultItem>>[
    await repository.getTrendingAnime(
      page: 1,
      perPage: 12,
      filters: const SearchFilters(
          medium: SearchMedium.anime, sort: SearchSort.trending),
    ),
    await repository.getTrendingManga(
      page: 1,
      perPage: 12,
      filters: const SearchFilters(
          medium: SearchMedium.manga, sort: SearchSort.popular),
    ),
  ];

  for (final genre in genres) {
    candidateBuckets.add(
      await repository.getTrendingAnime(
        page: 1,
        perPage: 10,
        filters: SearchFilters(
          medium: SearchMedium.anime,
          sort: SearchSort.popular,
          includedTags: {genre},
        ),
      ),
    );
    candidateBuckets.add(
      await repository.getTrendingManga(
        page: 1,
        perPage: 10,
        filters: SearchFilters(
          medium: SearchMedium.manga,
          sort: SearchSort.popular,
          includedTags: {genre},
        ),
      ),
    );
  }

  candidateBuckets.add(
    await repository.getTrendingAnime(
      page: 2,
      perPage: 8,
      filters: const SearchFilters(
          medium: SearchMedium.anime, sort: SearchSort.popular),
    ),
  );
  candidateBuckets.add(
    await repository.getTrendingManga(
      page: 2,
      perPage: 8,
      filters: const SearchFilters(
          medium: SearchMedium.manga, sort: SearchSort.trending),
    ),
  );

  final deduped = <String, SearchResultItem>{};
  for (final bucket in candidateBuckets) {
    for (final item in bucket) {
      deduped.putIfAbsent(item.id, () => item);
    }
  }
  return deduped.values.toList();
}

String _librarySignature(List<TrackableContent> library) {
  final parts = library
      .map((item) =>
          '${item.id}:${item.currentProgress}:${item.totalProgress}:${item.rating ?? 0}:${item.updatedAt.toIso8601String()}')
      .toList()
    ..sort();
  return parts.join('|');
}
