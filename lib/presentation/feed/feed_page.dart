import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/feed_post.dart';
import 'feed_notifier.dart';
import '../router/app_route_paths.dart';
import '../shared/async_state_switcher.dart';
import '../shared/local_post_card.dart';
import '../shared/error_retry_panel.dart';
import '../shared/feed_skeleton_card.dart';
import '../shared/location_permission_callout.dart';
import '../theme/app_tokens.dart';

/// Phase 6 でローカルフィードを実装。
///
/// BeReal 風: [FeedReady] / [FeedRefreshing] 時は縦 [PageView] で 1 画面 1 投稿。
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  static const int _skeletonCardCount = 3;
  static const int _loadMoreLeadPages = 3;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openComposeAndRefreshIfCreated() async {
    final created = await context.push<bool>(AppRoutePaths.compose);
    if (!mounted) return;
    if (created != true) return;
    final ok = await ref.read(feedNotifierProvider.notifier).refresh();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('更新できませんでした')));
    }
  }

  Future<void> _onRefreshPressed() async {
    final ok = await ref.read(feedNotifierProvider.notifier).refresh();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('更新できませんでした')));
    }
  }

  void _onFeedPageChanged(
    int index,
    int postCount, {
    required bool hasMore,
    required bool loadingMore,
  }) {
    if (!hasMore || loadingMore || postCount <= 0) return;
    final lead = math.min(_loadMoreLeadPages, postCount);
    final triggerIndex = postCount - lead;
    if (index < triggerIndex) return;
    ref.read(feedNotifierProvider.notifier).loadMore().then((ok) {
      if (!mounted || ok) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('続きを読み込めませんでした')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    ref.listen<FeedState>(feedNotifierProvider, (previous, next) {
      if (previous is FeedRefreshing && next is FeedReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) return;
          _pageController.jumpToPage(0);
        });
      }
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'feed_compose_fab',
        tooltip: '投稿を作成',
        onPressed: _openComposeAndRefreshIfCreated,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: switch (feedState) {
        FeedReady(:final posts, :final loadingMore, :final hasMore) =>
          _buildPagerStack(
            context,
            posts: posts,
            loadingMore: loadingMore,
            hasMore: hasMore,
          ),
        FeedRefreshing(:final posts, :final hasMore) => _buildPagerStack(
          context,
          posts: posts,
          loadingMore: false,
          hasMore: hasMore,
        ),
        _ => _buildNonPagerBody(context, feedState),
      },
    );
  }

  Widget _buildPagerStack(
    BuildContext context, {
    required List<FeedPost> posts,
    required bool loadingMore,
    required bool hasMore,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          itemCount: posts.length,
          onPageChanged: (i) => _onFeedPageChanged(
            i,
            posts.length,
            hasMore: hasMore,
            loadingMore: loadingMore,
          ),
          itemBuilder: (context, index) {
            final p = posts[index];
            return LocalPostCard(
              post: p,
              immersive: true,
              onTap: () async {
                final deleted = await context.push<bool>(
                  AppRoutePaths.postDetail(p.id.value),
                );
                if (!context.mounted) return;
                if (deleted != true) return;
                final ok = await ref
                    .read(feedNotifierProvider.notifier)
                    .refresh();
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('更新できませんでした')));
                }
              },
            );
          },
        ),
        if (loadingMore && hasMore)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            ),
          ),
        _FeedTopChrome(
          lightOnDark: true,
          onRefresh: _onRefreshPressed,
          onSettings: () => context.push(AppRoutePaths.settings),
        ),
      ],
    );
  }

  Widget _buildNonPagerBody(BuildContext context, FeedState feedState) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeedTopChrome(
          lightOnDark: false,
          onRefresh: () async {
            final ok = await ref.read(feedNotifierProvider.notifier).refresh();
            if (!context.mounted) return;
            if (!ok) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('更新できませんでした')));
            }
          },
          onSettings: () => context.push(AppRoutePaths.settings),
        ),
        Expanded(
          child: ColoredBox(
            color: theme.colorScheme.surface,
            child: switch (feedState) {
              FeedLocationDenied() => Center(
                child: LocationPermissionCallout(
                  onOpenSettings: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
              ),
              FeedInitial() || FeedLoading() => Semantics(
                label: '近くの投稿を読み込んでいます',
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.spaceUnit,
                  ),
                  children: List.generate(
                    _skeletonCardCount,
                    (_) => const FeedSkeletonCard(),
                  ),
                ),
              ),
              FeedEmpty() || FeedError() => AsyncStateSwitcher(
                phase: _asyncPhase(feedState),
                loading: (_) => const SizedBox.shrink(),
                ready: (_) => const SizedBox.shrink(),
                empty: (ctx) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'まだ近くに投稿がありません',
                          style: Theme.of(ctx).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTokens.spaceUnit * 2),
                        FilledButton.icon(
                          onPressed: () async {
                            final created = await ctx.push<bool>(
                              AppRoutePaths.compose,
                            );
                            if (!ctx.mounted) return;
                            if (created != true) return;
                            final ok = await ref
                                .read(feedNotifierProvider.notifier)
                                .refresh();
                            if (!ctx.mounted) return;
                            if (!ok) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('更新できませんでした')),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('最初の投稿をする'),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (ctx) {
                  final msg = switch (feedState) {
                    FeedError(:final message) => message,
                    _ => '',
                  };
                  return ErrorRetryPanel(
                    message: msg,
                    onRetry: () =>
                        ref.read(feedNotifierProvider.notifier).loadInitial(),
                  );
                },
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    );
  }

  AsyncViewPhase _asyncPhase(FeedState s) {
    return switch (s) {
      FeedEmpty() => AsyncViewPhase.empty,
      FeedError() => AsyncViewPhase.error,
      _ => AsyncViewPhase.ready,
    };
  }
}

/// フィード上部のタイトル・更新・設定（オーバーレイ時は半透明黒背景）。
class _FeedTopChrome extends StatelessWidget {
  const _FeedTopChrome({
    required this.lightOnDark,
    required this.onRefresh,
    required this.onSettings,
  });

  final bool lightOnDark;
  final Future<void> Function() onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = lightOnDark ? Colors.white : theme.colorScheme.onSurface;
    final bg = lightOnDark
        ? const Color(0xCC000000)
        : theme.colorScheme.surface;

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const SizedBox(width: AppTokens.spaceUnit),
              Expanded(
                child: Text(
                  '近くの投稿',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: '更新',
                onPressed: () => onRefresh(),
                icon: Icon(Icons.refresh, color: fg),
              ),
              IconButton(
                tooltip: '設定',
                onPressed: onSettings,
                icon: Icon(Icons.settings_outlined, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
