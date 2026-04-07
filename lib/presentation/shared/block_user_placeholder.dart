import 'package:flutter/material.dart';

/// Phase 10-3-2 までサーバ保存なし。確認後に案内の SnackBar を表示する。
Future<void> showBlockUserPlaceholderDialog(
  BuildContext context, {
  String? subjectLabel,
}) async {
  final label = subjectLabel?.trim();
  final body = label == null || label.isEmpty
      ? 'ブロックすると、そのユーザーの投稿やコメントがあなたには表示されなくなります。'
      : '「$label」をブロックすると、そのユーザーの投稿やコメントがあなたには表示されなくなります。';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('ユーザーをブロック'),
      content: Text(
        '$body\n\n保存処理は次の実装で有効になります。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('ブロックする'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ブロックの保存は次の実装で利用できます。'),
      ),
    );
  }
}
