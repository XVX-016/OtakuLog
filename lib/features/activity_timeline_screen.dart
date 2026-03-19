import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/features/activity_models.dart';
import 'package:intl/intl.dart';

class ActivityTimelineScreen extends ConsumerWidget {
  const ActivityTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityTimelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ACTIVITY')),
      body: activityAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const GTEmptyState(
              icon: Icons.history_toggle_off,
              title: 'No activity yet',
              description: 'Start logging to build your history.',
            );
          }

          final grouped = <DateTime, List<ActivityItem>>{};
          for (final item in items) {
            final day = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
            grouped.putIfAbsent(day, () => []).add(item);
          }

          final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final entries = grouped[day]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(day),
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entries.map(_activityTile),
                  ],
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ActivitySkeleton(),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
        ),
      ),
    );
  }

  Widget _activityTile(ActivityItem item) {
    final isAnime = item.type == ActivityItemType.anime;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isAnime ? AppTheme.accent : Colors.green).withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAnime ? Icons.play_arrow_rounded : Icons.menu_book_rounded,
              color: isAnime ? AppTheme.accent : Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.actionLabel,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateFormat('h:mm a').format(item.timestamp)} | ${item.minutesAdded} min',
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
