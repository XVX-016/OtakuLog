import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/data/remote/mangadex_service.dart';
import 'package:otakulog/features/reader/manga_reader_notifier.dart';
import 'package:shimmer/shimmer.dart';

class MangaReaderScreen extends ConsumerStatefulWidget {
  final MangaReaderArgs args;

  const MangaReaderScreen({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends ConsumerState<MangaReaderScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  PageController? _pageController;
  Timer? _scrollDebounce;
  Timer? _chromeAutoHideTimer;
  List<GlobalKey> _pageKeys = const [];

  MangaReaderArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleVerticalScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounce?.cancel();
    _chromeAutoHideTimer?.cancel();
    _scrollController
      ..removeListener(_handleVerticalScroll)
      ..dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final notifier = ref.read(mangaReaderNotifierProvider(_args).notifier);
    final readerState = ref.read(mangaReaderNotifierProvider(_args));
    if (readerState.chaptersLoadError != null && readerState.chapters.isEmpty) {
      notifier.loadInitial();
      return;
    }
    if (readerState.chapterLoadError != null) {
      notifier.retryCurrentChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mangaReaderNotifierProvider(_args));
    _syncPageResources(state);
    _syncChromeTimer(state);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildBody(context, state),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !state.showChrome,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: state.showChrome ? 1 : 0,
                child: _ReaderChrome(
                  args: _args,
                  state: state,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MangaReaderState state) {
    if (state.isLoadingChapters && state.chapters.isEmpty) {
      return const _ReaderLoadingScaffold();
    }

    if (state.chaptersLoadError != null && state.chapters.isEmpty) {
      return _ReaderErrorScaffold(
        message: state.chaptersLoadError!,
        onRetry: () =>
            ref.read(mangaReaderNotifierProvider(_args).notifier).loadInitial(),
      );
    }

    if (state.isLoadingChapter) {
      return _ReaderChapterSkeleton(onTap: _toggleChrome);
    }

    if (state.chapterLoadError != null) {
      return _ReaderErrorScaffold(
        message: state.chapterLoadError!,
        onRetry: () =>
            ref.read(mangaReaderNotifierProvider(_args).notifier).retryCurrentChapter(),
      );
    }

    if (!state.hasPages) {
      return _ReaderErrorScaffold(
        message: 'This chapter has no readable pages.',
        onRetry: () =>
            ref.read(mangaReaderNotifierProvider(_args).notifier).retryCurrentChapter(),
      );
    }

    return state.mode == MangaReaderMode.vertical
        ? _buildVerticalReader(state)
        : _buildPagedReader(state);
  }

  Widget _buildVerticalReader(MangaReaderState state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 48) {
          ref
              .read(mangaReaderNotifierProvider(_args).notifier)
              .setCurrentPageIndex(state.pages.length - 1);
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          top: 96,
          bottom: 96,
        ),
        itemCount: state.pages.length,
        itemBuilder: (context, index) {
          final page = state.pages[index];
          return KeyedSubtree(
            key: _pageKeys[index],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleReaderTap(
                  details.localPosition.dx,
                  MediaQuery.of(context).size.width,
                ),
                child: MangaReaderPageImage(
                  asset: page,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagedReader(MangaReaderState state) {
    final controller = _pageController!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        _handleReaderTap(details.localPosition.dx, MediaQuery.of(context).size.width);
      },
      child: PageView.builder(
        controller: controller,
        itemCount: state.pages.length,
        onPageChanged: (index) {
          ref.read(mangaReaderNotifierProvider(_args).notifier).setCurrentPageIndex(index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: MangaReaderPageImage(
                asset: state.pages[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleChrome() {
    final notifier = ref.read(mangaReaderNotifierProvider(_args).notifier);
    final state = ref.read(mangaReaderNotifierProvider(_args));
    final nextVisible = !state.showChrome;
    notifier.setChromeVisible(nextVisible);
    if (nextVisible) {
      _scheduleChromeAutoHide();
    } else {
      _chromeAutoHideTimer?.cancel();
    }
  }

  void _handleReaderTap(double dx, double width) {
    if (dx > width * 0.35 && dx < width * 0.65) {
      _toggleChrome();
      return;
    }

    final state = ref.read(mangaReaderNotifierProvider(_args));
    if (state.mode != MangaReaderMode.paged) return;
    _keepChromeAlive();

    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;

    if (dx <= width * 0.35) {
      controller.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _syncPageResources(MangaReaderState state) {
    if (_pageKeys.length != state.pages.length) {
      _pageKeys = List.generate(state.pages.length, (_) => GlobalKey());
    }

    if (state.mode == MangaReaderMode.paged) {
      final current = _pageController;
      if (current == null) {
        _pageController = PageController(initialPage: state.currentPageIndex);
      } else if (current.hasClients && current.page?.round() != state.currentPageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && current.hasClients) {
            current.jumpToPage(state.currentPageIndex);
          }
        });
      }
    }
  }

  void _handleVerticalScroll() {
    final state = ref.read(mangaReaderNotifierProvider(_args));
    if (state.mode != MangaReaderMode.vertical || state.pages.isEmpty) return;
    _keepChromeAlive();

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;

      final viewportHeight = MediaQuery.of(context).size.height;
      var closestIndex = state.currentPageIndex;
      var closestDistance = double.infinity;

      for (var i = 0; i < _pageKeys.length; i++) {
        final renderObject = _pageKeys[i].currentContext?.findRenderObject();
        if (renderObject is! RenderBox) continue;
        final top = renderObject.localToGlobal(Offset.zero).dy;
        final distance = (top - viewportHeight * 0.2).abs();
        if (distance < closestDistance) {
          closestDistance = distance;
          closestIndex = i;
        }
      }

      ref.read(mangaReaderNotifierProvider(_args).notifier).setCurrentPageIndex(closestIndex);
    });
  }

  void _syncChromeTimer(MangaReaderState state) {
    if (!state.showChrome) {
      _chromeAutoHideTimer?.cancel();
      _chromeAutoHideTimer = null;
      return;
    }
    _scheduleChromeAutoHide();
  }

  void _keepChromeAlive() {
    ref.read(mangaReaderNotifierProvider(_args).notifier).setChromeVisible(true);
    _scheduleChromeAutoHide();
  }

  void _scheduleChromeAutoHide() {
    _chromeAutoHideTimer?.cancel();
    _chromeAutoHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      ref.read(mangaReaderNotifierProvider(_args).notifier).setChromeVisible(false);
    });
  }
}

class _ReaderChrome extends ConsumerWidget {
  final MangaReaderArgs args;
  final MangaReaderState state;

  const _ReaderChrome({
    super.key,
    required this.args,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.pages.isEmpty
        ? 0.0
        : (state.currentPageIndex + 1) / state.pages.length;

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xD9101014),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          args.manga.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          state.currentChapter?.chapterLabel ?? 'Chapter',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB8BAC6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<MangaReaderMode>(
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        const BorderSide(color: Colors.white10),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFFB11F3C);
                        }
                        return const Color(0xFF17181F);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected)
                            ? Colors.white
                            : AppTheme.primaryText;
                      }),
                    ),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: MangaReaderMode.vertical,
                        icon: Icon(Icons.view_stream),
                        tooltip: 'Vertical',
                      ),
                      ButtonSegment(
                        value: MangaReaderMode.paged,
                        icon: Icon(Icons.chrome_reader_mode),
                        tooltip: 'Paged',
                      ),
                    ],
                    selected: {state.mode},
                    onSelectionChanged: (selection) {
                      ref
                          .read(mangaReaderNotifierProvider(args).notifier)
                          .setMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xD9101014),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 108,
                        child: Text(
                          'Page ${state.pages.isEmpty ? 0 : state.currentPageIndex + 1} / ${state.pages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          color: const Color(0xFFB11F3C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(mangaReaderNotifierProvider(args).notifier)
                                .goToAdjacentChapter(-1),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x55FFFFFF)),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Previous Chapter'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => ref
                                .read(mangaReaderNotifierProvider(args).notifier)
                                .goToAdjacentChapter(1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB11F3C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Next Chapter'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderLoadingScaffold extends StatelessWidget {
  const _ReaderLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.accent),
    );
  }
}

class _ReaderErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ReaderErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderChapterSkeleton extends StatelessWidget {
  final VoidCallback onTap;

  const _ReaderChapterSkeleton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 96, 16, 96),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: AppTheme.surface,
              highlightColor: AppTheme.elevated,
              child: Container(
                height: 340,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MangaReaderPageImage extends StatefulWidget {
  final MangaDexPageAsset asset;
  final BoxFit fit;

  const MangaReaderPageImage({
    super.key,
    required this.asset,
    required this.fit,
  });

  @override
  State<MangaReaderPageImage> createState() => _MangaReaderPageImageState();
}

class _MangaReaderPageImageState extends State<MangaReaderPageImage> {
  late int _urlIndex;

  List<String> get _urls => [
        widget.asset.primaryUrl,
        if (widget.asset.fallbackUrl != null) widget.asset.fallbackUrl!,
      ];

  @override
  void initState() {
    super.initState();
    _urlIndex = 0;
  }

  @override
  void didUpdateWidget(covariant MangaReaderPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.primaryUrl != widget.asset.primaryUrl ||
        oldWidget.asset.fallbackUrl != widget.asset.fallbackUrl) {
      _urlIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asset.localPath != null) {
      return Image.file(
        File(widget.asset.localPath!),
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _errorFallback(),
      );
    }

    final imageUrl = _urls[_urlIndex];
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: widget.fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: AppTheme.surface,
        highlightColor: AppTheme.elevated,
        child: Container(
          color: AppTheme.surface,
          constraints: const BoxConstraints(minHeight: 320),
        ),
      ),
      errorWidget: (context, url, error) {
        final message = error.toString().toLowerCase();
        final looksRetryable = message.contains('500') ||
            message.contains('502') ||
            message.contains('503') ||
            message.contains('504');

        if (looksRetryable && _urlIndex + 1 < _urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _urlIndex += 1);
            }
          });
          return Container(
            color: AppTheme.surface,
            constraints: const BoxConstraints(minHeight: 320),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          );
        }

        return _errorFallback();
      },
    );
  }

  Widget _errorFallback() {
    return Container(
      color: AppTheme.surface,
      constraints: const BoxConstraints(minHeight: 320),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              'Page ${widget.asset.index + 1} failed to load',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => setState(() => _urlIndex = 0),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}
