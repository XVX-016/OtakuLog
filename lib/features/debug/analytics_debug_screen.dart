import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/app/theme.dart';

class AnalyticsDebugScreen extends ConsumerWidget {
  const AnalyticsDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ANALYTICS DEBUG')),
      body: analyticsAsync.when(
        data: (snapshot) {
          final counters = snapshot.counters.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (counters.isEmpty)
                const Text('No analytics events recorded yet.',
                    style: TextStyle(color: AppTheme.secondaryText))
              else
                ...counters.map(
                  (entry) => ListTile(
                    title: Text(entry.key,
                        style: const TextStyle(color: AppTheme.primaryText)),
                    trailing: Text('${entry.value}',
                        style: const TextStyle(color: AppTheme.accent)),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(localAnalyticsServiceProvider).reset();
                  ref.invalidate(analyticsSnapshotProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analytics reset'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('RESET ANALYTICS'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppTheme.secondaryText)),
        ),
      ),
    );
  }
}
