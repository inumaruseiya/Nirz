import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/feed_post.dart';
import 'feed_notifier.dart';
import '../router/app_route_paths.dart';
import '../shared/local_post_card.dart';
import '../theme/app_tokens.dart';

/// Phase 6 でローカルフィードを実装。
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  static const double _loadMoreExtent = 240;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('続きを読み込めませんでした')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feed_compose_fab',
        tooltip: '投稿を作成',
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit,
        ),
        onPressed: () => context.push(AppRoutePaths.compose),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('投稿'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final ok = await ref.read(feedNotifierProvider.notifier).refresh();
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新できませんでした')),
            );
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
      FeedInitial() || FeedLoading() => [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      FeedReady(:final posts, :final loadingMore, :final hasMore) => [
          ..._postListSlivers(
            posts,
            showTrailingLoader: loadingMore && hasMore,
          ),
        ],
      FeedRefreshing(:final posts) => [
          ..._postListSlivers(posts, showTrailingLoader: false),
        ],
      FeedEmpty() => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'まだ近くに投稿がありません',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      FeedLocationDenied() => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '位置情報を利用できないため、近くの投稿を表示できません。',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      FeedError(:final message) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(feedNotifierProvider.notifier).loadInitial(),
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
    };
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
            onTap: () => context.push(AppRoutePaths.postDetail(p.id.value)),
          );
        },
      ),
    ];
  }
}
