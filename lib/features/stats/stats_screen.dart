import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';
import 'package:otakulog/domain/entities/user_session.dart';
import 'package:otakulog/domain/services/stats_service.dart';
import 'package:otakulog/features/stats/models/wrapped_summary.dart';
import 'package:otakulog/features/stats/widgets/heatmap.dart';
import 'package:otakulog/features/stats/widgets/share/lifetime_stats_card.dart';
import 'package:otakulog/features/stats/widgets/share/monthly_summary_card.dart';
import 'package:otakulog/features/stats/widgets/share/share_preview_sheet.dart';
import 'package:intl/intl.dart';

enum StatsShareType { monthly, lifetime }

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    final libraryAsync = ref.watch(combinedLibraryProvider);
    final monthlyWrappedAsync = ref.watch(monthlyWrappedProvider);
    final statsService = ref.watch(statsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ANALYTICS'),
        actions: [
          IconButton(
            onPressed: () => _showSharePicker(context, ref),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            onPressed: () => context.push('/activity'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: libraryAsync.when(
        data: (libraryItems) => sessionsAsync.when(
          data: (sessions) {
            final totalMinutes = statsService.calculateTotalMinutes(sessions);
            final totalHours = (totalMinutes / 60).toStringAsFixed(1);
            final weeklySummary = statsService.calculateWeeklySummary(sessions);
            final streakCount = statsService.calculateStreak(sessions);
            final hasWeeklyActivity =
                weeklySummary.values.any((value) => value > 0);
            final todayMinutes = statsService.calculateTodayMinutes(sessions);

            if (totalMinutes == 0 && libraryItems.isEmpty) {
              return _buildFirstRunEmptyState(context);
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (totalMinutes < 1)
                  const StatsEmptyState(
                    icon: Icons.timer_outlined,
                    message: 'No time logged yet',
                    hint:
                        'Log your first episode or chapter to start tracking.',
                  )
                else
                  _buildHeroStat(context, double.parse(totalHours)),
                const SizedBox(height: 24),
                const GTSectionHeader(title: 'Activity Breakdown'),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildAnimatedStatCard(
                      'Current Streak',
                      '$streakCount',
                      suffix: streakCount == 1 ? 'day' : 'days',
                      icon: Icons.local_fire_department,
                      color: AppTheme.accent,
                    ),
                    _buildAnimatedStatCard(
                      'Today',
                      '$todayMinutes',
                      suffix: 'm',
                      icon: Icons.today,
                      color: AppTheme.accent,
                    ),
                    _buildAnimatedStatCard(
                      'Total Hours',
                      totalHours,
                      suffix: 'hrs',
                      icon: Icons.timer_outlined,
                      color: AppTheme.accent,
                    ),
                    _buildAnimatedStatCard(
                      'Library',
                      '${libraryItems.length}',
                      suffix: 'items',
                      icon: Icons.collections_bookmark_outlined,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const GTSectionHeader(title: 'Weekly Trends'),
                const SizedBox(height: 8),
                if (!hasWeeklyActivity)
                  const StatsEmptyState(
                    icon: Icons.bar_chart_rounded,
                    message: 'No activity this week',
                    hint:
                        'Your weekly trends will appear here once you start logging.',
                  )
                else
                  _buildWeeklyChart(weeklySummary),
                const SizedBox(height: 24),
                const GTSectionHeader(title: 'Activity'),
                const SizedBox(height: 8),
                GTCard(
                  child: const ActivityHeatmap(),
                ),
                const SizedBox(height: 24),
                const GTSectionHeader(title: 'Wrapped'),
                const SizedBox(height: 8),
                _wrappedTile(
                  context,
                  monthlyWrappedAsync.valueOrNull,
                ),
                const SizedBox(height: 24),
                GTCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.accent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Review your full logging history',
                          style: TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/activity'),
                        child: const Text('OPEN'),
                      ),
                    ],
                  ),
                ),
                if (totalMinutes > 0) ...[
                  const SizedBox(height: 24),
                  _buildMostConsumedCard(sessions),
                ],
              ],
            );
          },
          loading: () => const _StatsLoadingState(),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
        loading: () => const _StatsLoadingState(),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildFirstRunEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insights_rounded, size: 64, color: Colors.white24),
            const SizedBox(height: 20),
            const Text(
              'Your stats live here',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search for anime or manga, add it to your library, and log progress to see analytics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search),
              label: const Text('Find something to watch'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(BuildContext context, double totalHours) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL TIME CONSUMED',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: totalHours),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
              );
            },
          ),
          const Text(
            'HOURS',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<DateTime, int> summary) {
    final sortedDates = summary.keys.toList()..sort((a, b) => a.compareTo(b));
    final barGroups = sortedDates.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: summary[entry.value]!.toDouble(),
            color: AppTheme.accent,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return GTCard(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                tooltipMargin: 8,
                getTooltipColor: (_) => Colors.white,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toStringAsFixed(1),
                    const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= sortedDates.length)
                      return const SizedBox.shrink();
                    final date = sortedDates[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.secondaryText, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            minY: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value, {
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostConsumedCard(List<UserSessionEntity> sessions) {
    var animeMins = 0;
    var mangaMins = 0;

    for (final session in sessions) {
      if (session.contentType == SessionContentType.anime) {
        animeMins += session.totalMinutes;
      } else {
        mangaMins += session.totalMinutes;
      }
    }

    final isAnime = animeMins >= mangaMins;
    final typeLabel = isAnime ? 'ANIME' : 'MANGA';
    final icon = isAnime ? Icons.tv : Icons.menu_book;

    return GTStatCard(
      title: 'Dominant Medium',
      value: typeLabel,
      icon: icon,
    );
  }

  Widget _wrappedTile(BuildContext context, WrappedSummary? summary) {
    return GTCard(
      onTap: summary == null
          ? null
          : () => context.push('/wrapped', extra: summary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary?.title ?? 'Wrapped',
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary?.heroValue ?? '0.0',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            summary?.heroLabel ?? 'hours tracked',
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showSharePicker(BuildContext context, WidgetRef ref) async {
    final shareType = await showModalBottomSheet<StatsShareType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _shareOption(context, StatsShareType.monthly, 'Monthly'),
              _shareOption(context, StatsShareType.lifetime, 'Lifetime'),
            ],
          ),
        ),
      ),
    );

    if (shareType == null || !context.mounted) return;

    final sessions = ref.read(allSessionsProvider).valueOrNull ??
        const <UserSessionEntity>[];
    final library = ref.read(combinedLibraryProvider).valueOrNull ??
        const <TrackableContent>[];
    final preview = _buildShareCard(
        shareType, ref.read(statsServiceProvider), sessions, library);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePreviewSheet(
        title: 'Share ${shareType.name} stats',
        child: preview,
      ),
    );
  }

  Widget _shareOption(BuildContext context, StatsShareType type, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.primaryText)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.secondaryText),
      onTap: () => Navigator.pop(context, type),
    );
  }

  Widget _buildShareCard(
    StatsShareType type,
    StatsService statsService,
    List<UserSessionEntity> sessions,
    List<TrackableContent> library,
  ) {
    switch (type) {
      case StatsShareType.monthly:
        final now = DateTime.now();
        final monthlySessions = sessions
            .where((session) =>
                session.endTime.isAfter(now.subtract(const Duration(days: 30))))
            .toList();
        return MonthlySummaryCard(
          totalHours: (statsService.calculateTotalMinutes(monthlySessions) / 60)
              .toStringAsFixed(1),
          topAnime:
              _topTitle(monthlySessions, library, SessionContentType.anime),
          topManga:
              _topTitle(monthlySessions, library, SessionContentType.manga),
          mostActiveDay: _mostActiveDayLabel(
              statsService.calculateMostActiveDay(monthlySessions)),
        );
      case StatsShareType.lifetime:
        return LifetimeStatsCard(
          totalHours: (statsService.calculateTotalMinutes(sessions) / 60)
              .toStringAsFixed(1),
          totalEpisodes: statsService.calculateTotalUnits(
              sessions, SessionContentType.anime),
          totalChapters: statsService.calculateTotalUnits(
              sessions, SessionContentType.manga),
          longestStreak: statsService.calculateLongestStreak(sessions),
        );
    }
  }

  String _topTitle(
    List<UserSessionEntity> sessions,
    List<TrackableContent> library,
    SessionContentType type,
  ) {
    final unitsById = <String, int>{};
    for (final session
        in sessions.where((session) => session.contentType == type)) {
      unitsById.update(
          session.contentId, (value) => value + session.unitsConsumed,
          ifAbsent: () => session.unitsConsumed);
    }
    if (unitsById.isEmpty)
      return type == SessionContentType.anime ? 'No anime yet' : 'No manga yet';

    final topId = unitsById.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final item in library) {
      if (item.id == topId.first.key) {
        return item.title;
      }
    }
    return 'Unknown title';
  }

  String _mostActiveDayLabel(DateTime? day) {
    if (day == null) return 'No active day yet';
    return DateFormat('MMM d').format(day);
  }
}

class StatsEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const StatsEmptyState({
    required this.icon,
    required this.message,
    required this.hint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatsLoadingState extends StatelessWidget {
  const _StatsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(
        5,
        (index) => Container(
          height: index == 0 ? 180 : 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
