import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/features/stats/widgets/share/stats_share_card_shell.dart';

class MonthlySummaryCard extends StatelessWidget {
  final String totalHours;
  final String topAnime;
  final String topManga;
  final String mostActiveDay;

  const MonthlySummaryCard({
    super.key,
    required this.totalHours,
    required this.topAnime,
    required this.topManga,
    required this.mostActiveDay,
  });

  @override
  Widget build(BuildContext context) {
    return StatsShareCardShell(
      title: 'Monthly Summary',
      subtitle: 'Your strongest habits this month.',
      children: [
        Text(
          '$totalHours h',
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text('total hours', style: TextStyle(color: AppTheme.secondaryText)),
        const SizedBox(height: 24),
        _featureBlock('Top anime', topAnime),
        _featureBlock('Top manga', topManga),
        _featureBlock('Most active day', mostActiveDay),
      ],
    );
  }

  Widget _featureBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
