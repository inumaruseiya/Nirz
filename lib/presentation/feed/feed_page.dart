import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_route_paths.dart';
import 'feed_manual_refresh_provider.dart';

/// Phase 6 でローカルフィードを実装。
class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('近くの投稿'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutePaths.settings),
            tooltip: '設定',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'フィード（Phase 6）',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(AppRoutePaths.compose);
          if (!context.mounted) return;
          if (created == true) {
            ref.read(feedManualRefreshTriggerProvider.notifier).state++;
          }
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('投稿'),
      ),
    );
  }
}
