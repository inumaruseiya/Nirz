import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_route_paths.dart';

/// Phase 6 でローカルフィードを実装。
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'フィード（Phase 6）',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
