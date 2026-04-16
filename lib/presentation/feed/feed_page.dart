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
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  static const double _loadMoreExtent = 240;
  static const int _skeletonCardCount = 3;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScrollNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollNearEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    if (max <= 0) return;
    if (position.pixels < max - _loadMoreExtent) return;

    ref.read(feedNotifierProvider.notifier).loadMore().then((ok) {
      if (!mounted || ok) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('続きを読み込めませんでした')));
    });
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

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feed_compose_fab',
        tooltip: '投稿を作成',
        onPressed: _openComposeAndRefreshIfCreated,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('投稿'),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        onRefresh: () async {
          final ok = await ref.read(feedNotifierProvider.notifier).refresh();
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('更新できませんでした')));
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('近くの投稿'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutePaths.settings),
                  tooltip: '設定',
                ),
              ],
            ),
            ..._feedBodySlivers(context, feedState),
          ],
        ),
      ),
    );
  }

  List<Widget> _feedBodySlivers(BuildContext context, FeedState feedState) {
    return switch (feedState) {
      FeedReady(:final posts, :final loadingMore, :final hasMore) => [
        ..._postListSlivers(posts, showTrailingLoader: loadingMore && hasMore),
      ],
      FeedRefreshing(:final posts) => [
        ..._postListSlivers(posts, showTrailingLoader: false),
      ],
      FeedLocationDenied() => [
        _sliverFillAsyncChild(
          child: Center(
            child: LocationPermissionCallout(
              onOpenSettings: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        ),
      ],
      FeedInitial() || FeedLoading() => [
        SliverSemantics(
          label: '近くの投稿を読み込んでいます',
          sliver: SliverList.builder(
            itemCount: _skeletonCardCount,
            itemBuilder: (context, index) => const FeedSkeletonCard(),
          ),
        ),
      ],
      FeedEmpty() || FeedError() => [
        _sliverFillAsyncChild(
          child: AsyncStateSwitcher(
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
        ),
      ],
    };
  }

  AsyncViewPhase _asyncPhase(FeedState s) {
    return switch (s) {
      FeedEmpty() => AsyncViewPhase.empty,
      FeedError() => AsyncViewPhase.error,
      _ => AsyncViewPhase.ready,
    };
  }

  Widget _sliverFillAsyncChild({required Widget child}) {
    return SliverFillRemaining(hasScrollBody: false, child: child);
  }

  List<Widget> _postListSlivers(
    List<FeedPost> posts, {
    required bool showTrailingLoader,
  }) {
    final n = posts.length;
    return [
      SliverList.builder(
        itemCount: n + (showTrailingLoader ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= n) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final p = posts[index];
          return LocalPostCard(
            post: p,
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
    ];
  }
}
