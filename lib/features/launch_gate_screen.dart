import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';

class LaunchGateScreen extends ConsumerWidget {
  const LaunchGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user != null) {
            Future.microtask(() async {
              try {
                final library = await ref.read(combinedLibraryProvider.future);
                final sessions = await ref.read(allSessionsProvider.future);
                await ref.read(achievementServiceProvider).performRetroactiveUnlock(
                  library: library,
                  sessions: sessions,
                );
                ref.invalidate(unlockedAchievementsProvider);
              } catch (_) {}
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(user == null ? '/onboarding' : '/');
          });
          return const Center(child: CircularProgressIndicator());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Startup error: $error',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
        ),
      ),
    );
  }
}
