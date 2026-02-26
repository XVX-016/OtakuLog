import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(dailyActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goon Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            activities.when(
              data: (data) {
                final totalMinutes = data.fold<int>(0, (sum, item) => sum + item.minutesWatched + item.minutesRead);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Time Spent Today'),
                        const SizedBox(height: 8),
                        Text(
                          '${(totalMinutes / 60).toStringAsFixed(1)} Hours',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Mock adding an anime for MVP demonstration
                ref.read(trackerNotifierProvider.notifier).addAnime(
                  animeId: 1,
                  title: 'Example Anime',
                  totalEpisodes: 12,
                  durationPerEpisode: 24,
                );
                ref.invalidate(userAnimeListProvider);
                ref.invalidate(dailyActivityProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Mock Anime to Library'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
