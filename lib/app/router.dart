import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goon_tracker/app/providers.dart';
import 'package:goon_tracker/features/details/anime_details_screen.dart';
import 'package:goon_tracker/features/debug/analytics_debug_screen.dart';
import 'package:goon_tracker/features/details/manga_details_screen.dart';
import 'package:goon_tracker/features/activity_timeline_screen.dart';
import 'package:goon_tracker/features/home/home_screen.dart';
import 'package:goon_tracker/features/library/library_screen.dart';
import 'package:goon_tracker/features/launch_gate_screen.dart';
import 'package:goon_tracker/features/onboarding/onboarding_screen.dart';
import 'package:goon_tracker/features/search/search_screen.dart';
import 'package:goon_tracker/features/settings_v2_screen.dart';
import 'package:goon_tracker/features/stats/stats_screen.dart';
import 'package:goon_tracker/features/stats/wrapped_screen.dart';
import 'package:goon_tracker/features/stats/models/wrapped_summary.dart';
import 'package:goon_tracker/domain/entities/anime.dart';
import 'package:goon_tracker/domain/entities/manga.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/launch',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/launch',
      builder: (context, state) => const LaunchGateScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/activity',
      builder: (context, state) => const ActivityTimelineScreen(),
    ),
    GoRoute(
      path: '/debug/analytics',
      builder: (context, state) => const AnalyticsDebugScreen(),
    ),
    GoRoute(
      path: '/wrapped',
      builder: (context, state) {
        final summary = state.extra as WrappedSummary;
        return WrappedScreen(summary: summary);
      },
    ),
    GoRoute(
      path: '/content/:id/:type',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final type = state.pathParameters['type']!;

        return Consumer(
          builder: (context, ref, child) {
            if (type == 'anime') {
              final animeList = ref.watch(libraryAnimeProvider).value;
              AnimeEntity? anime;
              if (animeList != null) {
                for (final item in animeList.whereType<AnimeEntity>()) {
                  if (item.id == id) {
                    anime = item;
                    break;
                  }
                }
              }
              return AnimeDetailScreen(
                itemId: id,
                cachedAnime: anime,
              );
            } else {
              final mangaList = ref.watch(libraryMangaProvider).value;
              MangaEntity? manga;
              if (mangaList != null) {
                for (final item in mangaList.whereType<MangaEntity>()) {
                  if (item.id == id) {
                    manga = item;
                    break;
                  }
                }
              }
              return MangaDetailScreen(
                itemId: id,
                cachedManga: manga,
              );
            }
          },
        );
      },
    ),
  ],
);

class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/library');
        break;
      case 2:
        GoRouter.of(context).go('/search');
        break;
      case 3:
        GoRouter.of(context).go('/stats');
        break;
    }
  }
}
