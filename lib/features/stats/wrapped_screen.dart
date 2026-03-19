import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/core/widgets/gt_ui_components.dart';
import 'package:goon_tracker/features/stats/models/wrapped_summary.dart';
import 'package:goon_tracker/features/stats/widgets/share/share_preview_sheet.dart';
import 'package:goon_tracker/features/stats/widgets/share/wrapped_summary_card.dart';
import 'package:intl/intl.dart';

class WrappedScreen extends ConsumerWidget {
  final WrappedSummary summary;

  const WrappedScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final displayName = user?.displayName ?? 'Pilot';

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.periodType == WrappedPeriodType.weekly ? 'WEEKLY WRAPPED' : 'MONTHLY WRAPPED'),
        actions: [
          IconButton(
            onPressed: () => _share(context, displayName),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(summary.periodLabel, style: const TextStyle(color: AppTheme.secondaryText)),
                const SizedBox(height: 20),
                Text(
                  summary.headline,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.subheadline,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricCard('Hours', summary.heroValue)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Sessions', '${summary.sessionsCount}')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricCard('Episodes', '${summary.totalEpisodes}')),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Chapters', '${summary.totalChapters}')),
            ],
          ),
          const SizedBox(height: 20),
          const GTSectionHeader(title: 'Highlights'),
          GTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Top anime', summary.topAnime),
                _detailRow('Top manga', summary.topManga),
                _detailRow('Top genre', summary.topGenre),
                _detailRow(
                  'Most active day',
                  summary.mostActiveDay == null ? 'No active day yet' : DateFormat('EEE, MMM d').format(summary.mostActiveDay!),
                ),
                _detailRow('Current streak', '${summary.streak} days'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _share(context, displayName),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('SHARE WRAPPED'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return GTCard(
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
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
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
              letterSpacing: 1.1,
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

  Future<void> _share(BuildContext context, String displayName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePreviewSheet(
        title: summary.title,
        child: WrappedSummaryCard(summary: summary, displayName: displayName),
      ),
    );
  }
}
