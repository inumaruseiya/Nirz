import 'package:flutter/material.dart';

import '../../domain/value_objects/user_id.dart';

/// 設定など: UUID 文字列を入力してブロック確認 → [onConfirm]。
Future<void> showBlockUserByIdInputDialog(
  BuildContext context, {
  required Future<String?> Function(UserId blockedUserId) onConfirm,
}) async {
  final controller = TextEditingController();
  final submitted = await showDialog<String?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('ユーザーをブロック'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ユーザー ID（UUID）',
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
            border: OutlineInputBorder(),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('確認へ'),
          ),
        ],
      );
    },
  );
  controller.dispose();

  if (!context.mounted || submitted == null || submitted.isEmpty) return;

  final UserId blocked;
  try {
    blocked = UserId.parse(submitted);
  } catch (_) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('有効なユーザー ID（UUID）を入力してください。')),
    );
    return;
  }

  await showBlockUserConfirmDialog(
    context,
    subjectLabel: 'ユーザー ${blocked.value}',
    onConfirm: () => onConfirm(blocked),
  );
}

/// ブロック確認。確定時は [onConfirm] を実行し、成功時は SnackBar を表示する。
Future<void> showBlockUserConfirmDialog(
  BuildContext context, {
  String? subjectLabel,
  Future<String?> Function()? onConfirm,
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
        onConfirm == null
            ? '$body\n\n保存処理は次の実装で有効になります。'
            : body,
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

  if (confirmed != true || !context.mounted) return;

  if (onConfirm == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ブロックの保存は次の実装で利用できます。'),
      ),
    );
    return;
  }

  final err = await onConfirm();
  if (!context.mounted) return;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ブロックしました。')),
    );
  }
}
