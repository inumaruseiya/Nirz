import 'package:flutter/material.dart';

/// Phase 8 で投稿詳細を実装。
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投稿')),
      body: Center(
        child: Text(
          '投稿 ID: $postId\n（Phase 8）',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
