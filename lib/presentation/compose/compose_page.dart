import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 全画面モーダル（`fullscreenDialog`）で表示。Phase 7 で実装。
class ComposePage extends StatelessWidget {
  const ComposePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: '閉じる',
        ),
        title: const Text('投稿を作成'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '投稿作成（Phase 7）。この画面はモーダル遷移です。',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
