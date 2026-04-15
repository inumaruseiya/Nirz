import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 詳細設計 1.3: iOS は Cupertino モダリティ、それ以外は Material。
bool get useCupertinoDialogs => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// [showCupertinoDialog]（iOS）または [showDialog]（その他）。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (useCupertinoDialogs) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

/// 確認のみ（削除確認など）。破壊的アクションは iOS で `isDestructiveAction`。
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'キャンセル',
  required String confirmLabel,
  bool confirmIsDestructive = false,
}) {
  if (useCupertinoDialogs) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: confirmIsDestructive,
            isDefaultAction: !confirmIsDestructive,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        if (confirmIsDestructive)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
      ],
    ),
  );
}

/// 1 行テキスト入力。キャンセルは `null`、確定はトリム後の文字列（空可）。
Future<String?> showAdaptiveSingleLineInputDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String fieldLabel,
  required String hintText,
  String cancelLabel = 'キャンセル',
  String confirmLabel = 'OK',
  String initialValue = '',
  bool autocorrect = true,
  bool enableSuggestions = true,
}) {
  return showAppDialog<String?>(
    context: context,
    builder: (ctx) => _AdaptiveSingleLineInputDialog(
      title: title,
      message: message,
      fieldLabel: fieldLabel,
      hintText: hintText,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
    ),
  );
}

class _AdaptiveSingleLineInputDialog extends StatefulWidget {
  const _AdaptiveSingleLineInputDialog({
    required this.title,
    this.message,
    required this.fieldLabel,
    required this.hintText,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.initialValue,
    required this.autocorrect,
    required this.enableSuggestions,
  });

  final String title;
  final String? message;
  final String fieldLabel;
  final String hintText;
  final String cancelLabel;
  final String confirmLabel;
  final String initialValue;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<_AdaptiveSingleLineInputDialog> createState() =>
      _AdaptiveSingleLineInputDialogState();
}

class _AdaptiveSingleLineInputDialogState
    extends State<_AdaptiveSingleLineInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _popCancel(BuildContext ctx) {
    Navigator.of(ctx).pop(null);
  }

  void _popSubmit(BuildContext ctx) {
    Navigator.of(ctx).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (useCupertinoDialogs) {
      final msg = widget.message;
      return CupertinoAlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (msg != null && msg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                msg,
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            ],
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _controller,
              placeholder: widget.hintText.isNotEmpty
                  ? widget.hintText
                  : widget.fieldLabel,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => _popCancel(context),
            child: Text(widget.cancelLabel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => _popSubmit(context),
            child: Text(widget.confirmLabel),
          ),
        ],
      );
    }

    final msg = widget.message;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (msg != null && msg.isNotEmpty) Text(msg),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.fieldLabel,
              hintText: widget.hintText,
            ),
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _popCancel(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => _popSubmit(context),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// 画像ソース選択。iOS はアクションシート。非 iOS は `null`（呼び出し側で [showModalBottomSheet]）。
Future<ImageSourceChoice?> showAdaptiveImageSourceSheet(
  BuildContext context, {
  required bool includeCamera,
}) async {
  if (!useCupertinoDialogs) {
    return null;
  }
  return showCupertinoModalPopup<ImageSourceChoice>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: const Text('画像を追加'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(ImageSourceChoice.gallery),
          child: const Text('フォトライブラリ'),
        ),
        if (includeCamera)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(ImageSourceChoice.camera),
            child: const Text('カメラ'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: const Text('キャンセル'),
      ),
    ),
  );
}

/// [showAdaptiveImageSourceSheet] と compose で共有。
enum ImageSourceChoice { gallery, camera }
