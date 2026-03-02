import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';
import 'package:goon_tracker/domain/entities/user_session.dart';
import 'package:intl/intl.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final statsService = ref.watch(statsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ANALYTICS')),
      body: sessionsAsync.when(
        data: (sessions) {
          final totalHours = (statsService.calculateTotalMinutes(sessions) / 60).toStringAsFixed(1);
          final weeklySummary = statsService.calculateWeeklySummary(sessions);
          final streakCount = statsService.calculateStreak(sessions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroStat(context, double.parse(totalHours)),
                const SizedBox(height: 32),
                const GTSectionHeader(title: 'Weekly Activity'),
                _buildWeeklyChart(weeklySummary),
                const SizedBox(height: 32),
                const GTSectionHeader(title: 'Overview'),
                GTStatCard(
                  title: 'Current Streak',
                  value: '$streakCount Days',
                  icon: Icons.local_fire_department,
                ),
                const SizedBox(height: 12),
                GTStatCard(
                  title: 'Today Consumption',
                  value: '${statsService.calculateTodayMinutes(sessions)} Minutes',
                  icon: Icons.today,
                ),
                const SizedBox(height: 12),
                _buildMostConsumedCard(sessions),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeroStat(BuildContext context, double totalHours) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= sortedDates.length) return const SizedBox.shrink();
                    final date = sortedDates[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: const TextStyle(color: AppTheme.secondaryText, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildMostConsumedCard(List<UserSessionEntity> sessions) {
    int animeMins = 0;
    int mangaMins = 0;

    for (var s in sessions) {
      if (s.contentType == SessionContentType.anime) {
        animeMins += s.totalMinutes;
      } else {
        mangaMins += s.totalMinutes;
      }
    }

    final isAnime = animeMins >= mangaMins;
    final typeLabel = isAnime ? 'ANIME' : 'MANGA';
    final icon = isAnime ? Icons.tv : Icons.menu_book;

    return GTStatCard(
      title: 'Most Consumed Type',
      value: typeLabel,
      icon: icon,
    );
  }
}
