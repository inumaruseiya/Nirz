import 'package:flutter/material.dart';

import '../../domain/value_objects/user_id.dart';
import 'platform_adaptive_dialogs.dart';

/// 設定など: UUID 文字列を入力してブロック確認 → [onConfirm]。
Future<void> showBlockUserByIdInputDialog(
  BuildContext context, {
  required Future<String?> Function(UserId blockedUserId) onConfirm,
}) async {
  final submitted = await showAdaptiveSingleLineInputDialog(
    context: context,
    title: 'ユーザーをブロック',
    fieldLabel: 'ユーザー ID（UUID）',
    hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    cancelLabel: 'キャンセル',
    confirmLabel: '確認へ',
    autocorrect: false,
    enableSuggestions: false,
  );

  if (!context.mounted || submitted == null || submitted.isEmpty) return;

  final UserId blocked;
  try {
    blocked = UserId.parse(submitted);
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('有効なユーザー ID（UUID）を入力してください。')));
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

  final message = onConfirm == null ? '$body\n\n保存処理は次の実装で有効になります。' : body;

  final confirmed = await showAdaptiveConfirmDialog(
    context: context,
    title: 'ユーザーをブロック',
    message: message,
    cancelLabel: 'キャンセル',
    confirmLabel: 'ブロックする',
    confirmIsDestructive: true,
  );

  if (confirmed != true || !context.mounted) return;

  if (onConfirm == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ブロックの保存は次の実装で利用できます。')));
    return;
  }

  final err = await onConfirm();
  if (!context.mounted) return;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ブロックしました。')));
  }
}
