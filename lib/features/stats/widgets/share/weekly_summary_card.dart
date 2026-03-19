import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/features/stats/widgets/share/stats_share_card_shell.dart';

class WeeklySummaryCard extends StatelessWidget {
  final String totalHours;
  final int episodes;
  final int chapters;
  final int streak;

  const WeeklySummaryCard({
    super.key,
    required this.totalHours,
    required this.episodes,
    required this.chapters,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return StatsShareCardShell(
      title: 'Weekly Summary',
      subtitle: 'A snapshot of your last 7 days.',
      children: [
        _heroValue(totalHours, 'hours logged'),
        const SizedBox(height: 20),
        _metricRow('Episodes watched', '$episodes'),
        _metricRow('Chapters read', '$chapters'),
        _metricRow('Current streak', '$streak days'),
      ],
    );
  }

  Widget _heroValue(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 54,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.secondaryText)),
      ],
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondaryText)),
          Text(value, style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
