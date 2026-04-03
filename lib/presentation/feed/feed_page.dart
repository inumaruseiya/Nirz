import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'feed_notifier.dart';
import '../router/app_route_paths.dart';

/// Phase 6 でローカルフィードを実装。
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedNotifierProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutePaths.compose),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('投稿'),
      ),
      body: CustomScrollView(
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
      FeedReady(:final posts) => [
          SliverList.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final p = posts[index];
              return ListTile(
                title: Text(p.content),
                subtitle: Text(p.authorName ?? '匿名'),
              );
            },
          ),
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
}
