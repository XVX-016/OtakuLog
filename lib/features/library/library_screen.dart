import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeList = ref.watch(userAnimeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: animeList.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Your library is empty.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final anime = list[index];
              final progress = anime.watchedEpisodes / anime.totalEpisodes;

              return Card(
                margin: const EdgeInsets.bottom(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${anime.watchedEpisodes} / ${anime.totalEpisodes} eps'),
                          ElevatedButton(
                            onPressed: anime.watchedEpisodes < anime.totalEpisodes
                                ? () async {
                                    await ref.read(trackerNotifierProvider.notifier).logEpisode(anime);
                                    ref.invalidate(userAnimeListProvider);
                                    ref.invalidate(dailyActivityProvider);
                                  }
                                : null,
                            child: const Text('Log Episode'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}
