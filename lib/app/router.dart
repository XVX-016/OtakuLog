import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goon_tracker/features/home/home_screen.dart';
import 'package:goon_tracker/features/library/library_screen.dart';
import 'package:goon_tracker/features/search/search_screen.dart';
import 'package:goon_tracker/features/stats/stats_screen.dart';
import 'package:goon_tracker/features/details/anime_details_screen.dart';
import 'package:goon_tracker/features/details/manga_details_screen.dart';
import 'package:goon_tracker/features/tracker/tracker_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [
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
      path: '/content/:id/:type',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final type = state.pathParameters['type']!;
        
        return Consumer(
          builder: (context, ref, child) {
            if (type == 'anime') {
              final animeList = ref.watch(libraryAnimeProvider).value ?? [];
              final anime = animeList.firstWhere((a) => a.id == id);
              return AnimeDetailScreen(anime: anime);
            } else {
              final mangaList = ref.watch(libraryMangaProvider).value ?? [];
              final manga = mangaList.firstWhere((m) => m.id == id);
              return MangaDetailScreen(manga: manga);
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
