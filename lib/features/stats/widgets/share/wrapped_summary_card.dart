import 'package:flutter/material.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/features/stats/models/wrapped_summary.dart';
import 'package:goon_tracker/features/stats/widgets/share/stats_share_card_shell.dart';
import 'package:intl/intl.dart';

class WrappedSummaryCard extends StatelessWidget {
  final WrappedSummary summary;
  final String displayName;

  const WrappedSummaryCard({
    super.key,
    required this.summary,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return StatsShareCardShell(
      title: summary.title,
      subtitle: '$displayName • ${summary.periodLabel}',
      children: [
        Text(
          summary.heroValue,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 56,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(summary.headline, style: const TextStyle(color: AppTheme.secondaryText)),
        const SizedBox(height: 22),
        _metric('Top anime', summary.topAnime),
        _metric('Top manga', summary.topManga),
        _metric('Top genre', summary.topGenre),
        _metric('Most active day', summary.mostActiveDay == null ? 'No active day yet' : DateFormat('MMM d').format(summary.mostActiveDay!)),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
