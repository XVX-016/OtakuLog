import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/features/stats/widgets/share/stats_share_card_shell.dart';

class LifetimeStatsCard extends StatelessWidget {
  final String totalHours;
  final int totalEpisodes;
  final int totalChapters;
  final int longestStreak;

  const LifetimeStatsCard({
    super.key,
    required this.totalHours,
    required this.totalEpisodes,
    required this.totalChapters,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return StatsShareCardShell(
      title: 'Lifetime Stats',
      subtitle: 'Everything you have logged so far.',
      children: [
        Text(
          '$totalHours h',
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _pillMetric('Episodes', '$totalEpisodes'),
        _pillMetric('Chapters', '$totalChapters'),
        _pillMetric('Longest streak', '$longestStreak days'),
      ],
    );
  }

  Widget _pillMetric(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondaryText)),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
