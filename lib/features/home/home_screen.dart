import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/entities/user.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:goon_tracker/domain/services/recommendation_service.dart';
import 'package:goon_tracker/domain/services/stats_service.dart';
import 'package:goon_tracker/features/activity_models.dart';
import 'package:goon_tracker/features/details/widgets/content_preview_sheet.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';
import 'package:goon_tracker/features/search/models/search_result_item.dart';
import 'package:goon_tracker/features/search/widgets/search_result_card.dart';
import 'package:goon_tracker/features/stats/models/wrapped_summary.dart';
import 'package:goon_tracker/features/stats/widgets/share/share_preview_sheet.dart';
import 'package:goon_tracker/features/stats/widgets/share/wrapped_summary_card.dart';
import 'package:goon_tracker/features/tracker/tracker_feedback.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _bootstrappedRetention = false;
  String? _shownWrappedPeriodKey;
  final Set<String> _trackedRecommendationIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markAppSessionActive();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _scheduleReminderForBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(retentionPreferencesProvider);
    final sessionsAsync = ref.watch(allSessionsProvider);
    final libraryAsync = ref.watch(combinedLibraryProvider);
    final trackerState = ref.watch(trackerNotifierProvider);
    final activityAsync = ref.watch(activityTimelineProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final trendingAnimeAsync = ref.watch(trendingAnimeProvider);
    final trendingMangaAsync = ref.watch(trendingMangaProvider);
    final wrappedPromptAsync = ref.watch(wrappedPromptProvider);
    final monthlyWrappedAsync = ref.watch(monthlyWrappedProvider);
    final profileAsync = ref.watch(userPreferenceProfileProvider);
    final dailyActivityAsync = ref.watch(dailyActivityProvider);
    final statsService = ref.watch(statsServiceProvider);
    final recommendationService = ref.watch(recommendationServiceProvider);

    final user = userAsync.valueOrNull;
    final sessions = sessionsAsync.valueOrNull ?? const <UserSessionEntity>[];
    _trackRecommendationImpressions(
        recommendationsAsync.valueOrNull ?? const []);
    _handleRetentionBootstrap(user, prefsAsync);
    _handleWrappedPrompt(wrappedPromptAsync, user, context);
    _handleMilestone(profileAsync, prefsAsync, recommendationService);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _buildHeader(
                context,
                user,
                sessions,
                dailyActivityAsync.valueOrNull ?? const <DateTime, int>{},
                statsService,
                recommendationService,
                prefsAsync.valueOrNull?.highestUnlockedStreakMilestone ?? 0,
              ),
              const SizedBox(height: 24),
              libraryAsync.when(
                data: (items) => _buildContinueAndStats(
                  context,
                  user,
                  items,
                  sessions,
                  dailyActivityAsync.valueOrNull ?? const <DateTime, int>{},
                  trackerState,
                  statsService,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Error: $error',
                    style: const TextStyle(color: AppTheme.secondaryText)),
              ),
              const SizedBox(height: 24),
              _buildRecommendationsSection(
                  context, recommendationsAsync.valueOrNull ?? const []),
              const SizedBox(height: 24),
              _buildTrendingSection(
                context,
                _mixedTrending(trendingAnimeAsync.valueOrNull ?? const [],
                    trendingMangaAsync.valueOrNull ?? const []),
              ),
              const SizedBox(height: 24),
              _buildWrappedSection(
                context,
                monthlyWrappedAsync.valueOrNull,
              ),
              const SizedBox(height: 24),
              _buildRecentActivity(context, activityAsync),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(retentionPreferencesProvider);
    ref.invalidate(allSessionsProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(combinedLibraryProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(trendingAnimeProvider);
    ref.invalidate(trendingMangaProvider);
    ref.invalidate(retentionReminderProvider);
    ref.invalidate(weeklyWrappedProvider);
    ref.invalidate(monthlyWrappedProvider);
    ref.invalidate(wrappedPromptProvider);
    ref.invalidate(userPreferenceProfileProvider);
  }

  void _handleRetentionBootstrap(
    UserEntity? user,
    AsyncValue prefsAsync,
  ) {
    if (!_bootstrappedRetention && user != null && prefsAsync.hasValue) {
      _bootstrappedRetention = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prefs = await ref.read(retentionPreferencesProvider.future);
        await ref.read(reminderServiceProvider).cancelReminder();
        await ref.read(retentionPreferencesServiceProvider).save(
              prefs.copyWith(
                lastAppOpenedAtIso: DateTime.now().toIso8601String(),
                lastReminderScheduledForIso: null,
              ),
            );
        ref.invalidate(retentionPreferencesProvider);
      });
    }
  }

  void _handleWrappedPrompt(
    AsyncValue<WrappedSummary?> wrappedPromptAsync,
    UserEntity? user,
    BuildContext context,
  ) {
    final promptSummary = wrappedPromptAsync.valueOrNull;
    if (promptSummary != null &&
        promptSummary.periodType == WrappedPeriodType.monthly &&
        _shownWrappedPeriodKey != promptSummary.periodKey) {
      _shownWrappedPeriodKey = promptSummary.periodKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWrappedPrompt(context, promptSummary, user);
      });
    }
  }

  void _handleMilestone(
    AsyncValue<UserPreferenceProfile> profileAsync,
    AsyncValue prefsAsync,
    RecommendationService recommendationService,
  ) {
    final profile = profileAsync.valueOrNull;
    if (profile == null || !prefsAsync.hasValue) return;
    final milestone =
        recommendationService.milestoneForStreak(profile.currentStreak);
    if (milestone <= prefsAsync.value.highestUnlockedStreakMilestone) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await ref.read(retentionPreferencesProvider.future);
      await ref.read(retentionPreferencesServiceProvider).save(
            prefs.copyWith(highestUnlockedStreakMilestone: milestone),
          );
      ref.invalidate(retentionPreferencesProvider);
    });
  }

  Widget _buildHeader(
    BuildContext context,
    UserEntity? user,
    List<UserSessionEntity> sessions,
    Map<DateTime, int> dailyActivity,
    StatsService statsService,
    RecommendationService recommendationService,
    int highestMilestone,
  ) {
    final todayMinutes =
        dailyActivity[statsService.normalizedDay(DateTime.now())] ?? 0;
    final streak = statsService.calculateStreak(sessions);
    final milestone = highestMilestone > streak
        ? highestMilestone
        : recommendationService.milestoneForStreak(streak);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, ${user?.displayName ?? 'Pilot'}',
                style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                todayMinutes > 0
                    ? '$todayMinutes minutes logged today'
                    : 'Start logging to build your stats',
                style: const TextStyle(
                    color: AppTheme.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      streak > 0
                          ? '$streak day streak - ${recommendationService.milestoneLabel(milestone)}'
                          : 'Start your streak today',
                      style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => context.push('/settings'),
          style: IconButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.primaryText),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Widget _buildContinueAndStats(
    BuildContext context,
    UserEntity? user,
    List<TrackableContent> items,
    List<UserSessionEntity> sessions,
    Map<DateTime, int> dailyActivity,
    TrackerState trackerState,
    StatsService statsService,
  ) {
    final anime = items
        .whereType<AnimeEntity>()
        .where(_isActiveAnime)
        .cast<TrackableContent>()
        .toList();
    final manga = items
        .whereType<MangaEntity>()
        .where(_isActiveManga)
        .cast<TrackableContent>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContinueSection(context, user, 'Continue Watching', anime,
            '+1 Ep', trackerState, 'No anime in progress yet'),
        const SizedBox(height: 24),
        _buildContinueSection(context, user, 'Continue Reading', manga, '+1 Ch',
            trackerState, 'No manga in progress yet'),
        const SizedBox(height: 24),
        _buildSnapshotCards(items, sessions, dailyActivity, statsService),
      ],
    );
  }

  Widget _buildContinueSection(
    BuildContext context,
    UserEntity? user,
    String title,
    List<TrackableContent> items,
    String quickLabel,
    TrackerState trackerState,
    String emptyTitle,
  ) {
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GTSectionHeader(title: title),
        if (items.isEmpty)
          GTEmptyState(
            icon: Icons.play_circle_outline,
            title: emptyTitle,
            description: 'Start something from Search to build this row.',
            buttonLabel: 'Browse',
            onButtonPressed: () => context.go('/search'),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.take(8).length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return _continueCard(context, user, item, quickLabel,
                    trackerState.isBusy(item.id));
              },
            ),
          ),
      ],
    );
  }

  Widget _continueCard(BuildContext context, UserEntity? user,
      TrackableContent item, String quickLabel, bool isBusy) {
    final total = item.totalProgress;
    final progress = total > 0 ? item.currentProgress / total : 0.0;
    final progressText = item is AnimeEntity
        ? 'Ep ${item.currentEpisode} / ${total > 0 ? total : '?'}'
        : 'Ch ${(item as MangaEntity).currentChapter} / ${total > 0 ? total : '?'}';
    final cardWidth = MediaQuery.of(context).size.width * 0.78;
    return SizedBox(
      width: cardWidth,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: IntrinsicHeight(
          child: GTCard(
            onTap: () => _openDetails(context, item),
            padding: EdgeInsets.zero,
          child: Row(
            children: [
              GTCoverImage(
                imageUrl: _coverImage(user, item),
                title: item.title,
                width: 64,
                height: double.infinity,
                fit: BoxFit.cover,
                badge: item is AnimeEntity ? 'ANIME' : 'MANGA',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressText,
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 220),
                        builder: (context, value, _) =>
                            GTProgressBar(progress: value, height: 3),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.elevated,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item is AnimeEntity ? 'WATCHING' : 'READING',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedScale(
                  scale: isBusy ? 0.96 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: SizedBox(
                    width: 64,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          isBusy ? null : () => _quickLog(context, item, user),
                      child: Text(
                        isBusy ? '...' : quickLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotCards(
    List<TrackableContent> items,
    List<UserSessionEntity> sessions,
    Map<DateTime, int> dailyActivity,
    StatsService statsService,
  ) {
    final todayMinutes =
        dailyActivity[statsService.normalizedDay(DateTime.now())] ?? 0;
    final cards = [
      _smallStatCard('Today', '${todayMinutes}m', Icons.schedule),
      _smallStatCard('Streak', '${statsService.calculateStreak(sessions)}',
          Icons.local_fire_department_outlined),
      _smallStatCard(
          'Total Hours',
          (statsService.calculateTotalMinutes(sessions) / 60)
              .toStringAsFixed(1),
          Icons.timer_outlined),
      _smallStatCard(
          'Library', '${items.length}', Icons.collections_bookmark_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTSectionHeader(title: 'Today Snapshot'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (_, index) => cards[index],
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(
      BuildContext context, List<PersonalizedRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTSectionHeader(title: 'Recommended For You'),
        if (recommendations.isEmpty)
          const Text(
              'Your recommendations will sharpen as you log more. Trending is ready below.',
              style: TextStyle(color: AppTheme.secondaryText))
        else
          SizedBox(
            height: 264,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return SearchResultCard(
                  item: recommendation.item,
                  compact: true,
                  subtitleOverride: recommendation.explanationText,
                  onTap: () async {
                    await ref
                        .read(localAnalyticsServiceProvider)
                        .track('recommendation_click');
                    ref.invalidate(analyticsSnapshotProvider);
                    if (!context.mounted) return;
                    _showPreview(context, recommendation.item.content);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTrendingSection(
      BuildContext context, List<TrackableContent> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTSectionHeader(title: 'Trending Now'),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return SearchResultCard(
                item: SearchResultItem(
                  id: item.id,
                  content: item,
                  medium: item is AnimeEntity
                      ? SearchMedium.anime
                      : SearchMedium.manga,
                  tags: item.genres.take(4).toList(),
                  description: item.description,
                  score: item.rating,
                  totalCount:
                      item.totalProgress > 0 ? item.totalProgress : null,
                ),
                compact: true,
                subtitleOverride: item.genres.take(2).join(' | '),
                onTap: () => _showPreview(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWrappedSection(
      BuildContext context, WrappedSummary? monthlyWrapped) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GTSectionHeader(title: 'Wrapped'),
        _wrappedCard(context, monthlyWrapped, 'Monthly Wrapped'),
      ],
    );
  }

  Widget _wrappedCard(
      BuildContext context, WrappedSummary? summary, String fallbackTitle) {
    return GTCard(
      onTap: summary == null ? null : () => _openWrapped(context, summary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary?.title ?? fallbackTitle,
              style: const TextStyle(
                  color: AppTheme.primaryText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(summary?.heroValue ?? '0.0',
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(summary?.heroLabel ?? 'hours tracked',
              style:
                  const TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
          const SizedBox(height: 10),
          Text(summary?.headline ?? 'Build your habit to unlock this.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, AsyncValue<List<ActivityItem>> activityAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const GTSectionHeader(title: 'Recent Activity'),
            TextButton(
                onPressed: () => context.push('/activity'),
                child: const Text('VIEW ALL')),
          ],
        ),
        activityAsync.when(
          data: (items) => items.isEmpty
              ? const Text(
                  'Your latest logs will appear here once you start tracking.',
                  style: TextStyle(color: AppTheme.secondaryText))
              : Column(children: items.take(2).map(_activityRow).toList()),
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text('Error: $error',
              style: const TextStyle(color: AppTheme.secondaryText)),
        ),
      ],
    );
  }

  Widget _smallStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _activityRow(ActivityItem item) {
    final isAnime = item.type == ActivityItemType.anime;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(isAnime ? Icons.play_circle_outline : Icons.menu_book_outlined,
              color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
              child: Text(item.actionLabel,
                  style: const TextStyle(color: AppTheme.primaryText))),
          Text('${item.minutesAdded}m',
              style: const TextStyle(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }

  Future<void> _quickLog(
      BuildContext context, TrackableContent item, UserEntity? user) async {
    await ref.read(localAnalyticsServiceProvider).track('quick_log');
    ref.invalidate(analyticsSnapshotProvider);
    final result = item is AnimeEntity
        ? await ref
            .read(trackerNotifierProvider.notifier)
            .logAnimeEpisode(item, user: user)
        : await ref
            .read(trackerNotifierProvider.notifier)
            .logMangaChapter(item as MangaEntity, user: user);
    if (context.mounted) {
      await showTrackerFeedback(context, ref, result);
      await _refreshRetentionAfterLog();
    }
  }

  Future<void> _refreshRetentionAfterLog() async {
    await ref.read(reminderServiceProvider).cancelReminder();
    final prefs = await ref.read(retentionPreferencesProvider.future);
    await ref
        .read(retentionPreferencesServiceProvider)
        .save(prefs.copyWith(lastReminderScheduledForIso: null));
    ref.invalidate(retentionPreferencesProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(retentionReminderProvider);
    ref.invalidate(weeklyWrappedProvider);
    ref.invalidate(monthlyWrappedProvider);
    ref.invalidate(wrappedPromptProvider);
  }

  void _showPreview(BuildContext context, TrackableContent item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContentPreviewSheet(content: item),
    );
  }

  Future<void> _showWrappedPrompt(
      BuildContext context, WrappedSummary summary, UserEntity? user) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary.title,
                  style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(summary.headline,
                  style: const TextStyle(color: AppTheme.secondaryText)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _markWrappedShown(summary);
                      },
                      child: const Text('DISMISS'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await ref
                            .read(localAnalyticsServiceProvider)
                            .track('wrapped_open');
                        ref.invalidate(analyticsSnapshotProvider);
                        await _markWrappedShown(summary);
                        if (context.mounted) _openWrapped(context, summary);
                      },
                      child: const Text('VIEW'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await ref
                        .read(localAnalyticsServiceProvider)
                        .track('wrapped_share');
                    ref.invalidate(analyticsSnapshotProvider);
                    await _markWrappedShown(summary);
                    if (!context.mounted) return;
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SharePreviewSheet(
                        title: summary.title,
                        child: WrappedSummaryCard(
                            summary: summary,
                            displayName: user?.displayName ?? 'Pilot'),
                      ),
                    );
                  },
                  child: const Text('SHARE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markWrappedShown(WrappedSummary summary) async {
    final prefs = await ref.read(retentionPreferencesProvider.future);
    final next = summary.periodType == WrappedPeriodType.weekly
        ? prefs.copyWith(lastWeeklyWrappedPeriodKeyShown: summary.periodKey)
        : prefs.copyWith(lastMonthlyWrappedPeriodKeyShown: summary.periodKey);
    await ref.read(retentionPreferencesServiceProvider).save(next);
    ref.invalidate(retentionPreferencesProvider);
    ref.invalidate(wrappedPromptProvider);
  }

  List<TrackableContent> _mixedTrending(
      List<TrackableContent> anime, List<TrackableContent> manga) {
    final mixed = <TrackableContent>[];
    final maxLength = anime.length > manga.length ? anime.length : manga.length;
    for (var i = 0; i < maxLength; i++) {
      if (i < anime.length) mixed.add(anime[i]);
      if (i < manga.length) mixed.add(manga[i]);
    }
    return mixed;
  }

  void _openWrapped(BuildContext context, WrappedSummary summary) {
    context.push('/wrapped', extra: summary);
  }

  void _openDetails(BuildContext context, TrackableContent item) {
    final type = item is AnimeEntity ? 'anime' : 'manga';
    context.push('/content/${item.id}/$type');
  }

  bool _isActiveAnime(AnimeEntity anime) {
    if (anime.status == AnimeStatus.completed) return false;
    if (anime.totalEpisodes > 0) {
      return anime.currentEpisode < anime.totalEpisodes;
    }
    return true;
  }

  bool _isActiveManga(MangaEntity manga) {
    if (manga.status == MangaStatus.completed) return false;
    if (manga.totalChapters > 0) {
      return manga.currentChapter < manga.totalChapters;
    }
    return true;
  }

  String _coverImage(UserEntity? user, TrackableContent item) {
    return user?.blurCoverInPublic == true ? '' : item.coverImage;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _trackRecommendationImpressions(
      List<PersonalizedRecommendation> recommendations) {
    if (recommendations.isEmpty) return;
    final unseen = recommendations
        .where((item) => !_trackedRecommendationIds.contains(item.item.id))
        .toList();
    if (unseen.isEmpty) return;
    for (final item in unseen) {
      _trackedRecommendationIds.add(item.item.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final _ in unseen) {
        await ref
            .read(localAnalyticsServiceProvider)
            .track('recommendation_impression');
      }
      ref.invalidate(analyticsSnapshotProvider);
    });
  }

  Future<void> _markAppSessionActive() async {
    final prefs = await ref.read(retentionPreferencesProvider.future);
    await ref.read(reminderServiceProvider).cancelReminder();
    await ref.read(retentionPreferencesServiceProvider).save(
          prefs.copyWith(
            lastAppOpenedAtIso: DateTime.now().toIso8601String(),
            lastReminderScheduledForIso: null,
          ),
        );
    ref.invalidate(retentionPreferencesProvider);
  }

  Future<void> _scheduleReminderForBackground() async {
    final prefs = await ref.read(retentionPreferencesProvider.future);
    final reminder = await ref.read(retentionReminderProvider.future);
    final reminderService = ref.read(reminderServiceProvider);
    await reminderService.cancelReminder();

    final scheduledFor = reminder.scheduledFor;
    if (!prefs.notificationsEnabled || scheduledFor == null) {
      await ref.read(retentionPreferencesServiceProvider).save(
            prefs.copyWith(lastReminderScheduledForIso: null),
          );
      ref.invalidate(retentionPreferencesProvider);
      return;
    }

    final lastScheduled = prefs.lastReminderScheduledFor;
    final alreadyScheduledForSameDay = lastScheduled != null &&
        lastScheduled.year == scheduledFor.year &&
        lastScheduled.month == scheduledFor.month &&
        lastScheduled.day == scheduledFor.day;
    if (!alreadyScheduledForSameDay) {
      await reminderService.scheduleReminder(
        scheduledFor: scheduledFor,
        title: reminder.title,
        body: reminder.message,
      );
    }

    await ref.read(retentionPreferencesServiceProvider).save(
          prefs.copyWith(
              lastReminderScheduledForIso: scheduledFor.toIso8601String()),
        );
    ref.invalidate(retentionPreferencesProvider);
  }
}
