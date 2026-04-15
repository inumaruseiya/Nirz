import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// コメント入力＋送信（実装計画 Phase 9-1-2、詳細設計 4.5）。
///
/// [replyToLabel] が null のときはトップレベルコメント用。[onCancelReply] と組み合わせて返信モードを解除する。
class CommentComposer extends StatefulWidget {
  const CommentComposer({
    super.key,
    this.replyToLabel,
    this.onCancelReply,
    required this.onSubmit,
    this.enabled = true,
    this.maxLength = 2000,
    this.hintText = 'コメントを入力…',
  });

  /// 返信時のみ。表示名など短い文字列（例: 親コメントの投稿者名）。
  final String? replyToLabel;

  /// 返信バナーの閉じる。トップレベルに戻すときに呼ぶ。
  final VoidCallback? onCancelReply;

  /// 送信処理。空・空白のみは呼ばれない。
  final Future<void> Function(String content) onSubmit;

  /// false のとき入力・送信を無効化（読み込み中等）。
  final bool enabled;

  /// 本文の最大文字数（Compose と同程度の目安）。
  final int maxLength;

  final String hintText;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final TextEditingController _controller = TextEditingController();

  bool _emptySubmitAttempted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _contentValid => _controller.text.trim().isNotEmpty;

  String? get _errorText {
    if (!_emptySubmitAttempted || _contentValid) return null;
    return 'コメントを入力してください。';
  }

  Future<void> _handleSubmit() async {
    if (!widget.enabled || _submitting) return;
    if (!_contentValid) {
      setState(() => _emptySubmitAttempted = true);
      return;
    }
    setState(() {
      _emptySubmitAttempted = false;
      _submitting = true;
    });
    try {
      await widget.onSubmit(_controller.text.trim());
      if (mounted) {
        _controller.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEdit = widget.enabled && !_submitting;
    final replyLabel = widget.replyToLabel?.trim();
    final inReplyMode =
        replyLabel != null &&
        replyLabel.isNotEmpty &&
        widget.onCancelReply != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inReplyMode) ...[
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceUnit,
                vertical: AppTokens.spaceUnit / 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: '返信先: $replyLabel',
                      child: Text(
                        '返信先: $replyLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '返信をやめる',
                    onPressed: canEdit ? widget.onCancelReply : null,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        AppTokens.minTapTarget,
                        AppTokens.minTapTarget,
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceUnit),
        ],
        Semantics(
          label: inReplyMode ? '返信の本文' : 'コメント本文',
          hint: '最大 ${widget.maxLength} 文字。送信ボタンで投稿。',
          textField: true,
          child: TextField(
            controller: _controller,
            enabled: canEdit,
            maxLength: widget.maxLength,
            maxLines: 4,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: _errorText,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
              ),
              counterText: '',
            ),
            onChanged: (_) {
              setState(() {
                if (_emptySubmitAttempted && _contentValid) {
                  _emptySubmitAttempted = false;
                }
              });
            },
          ),
        ),
        const SizedBox(height: AppTokens.spaceUnit / 2),
        Row(
          children: [
            Text(
              '${_controller.text.length}/${widget.maxLength}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: canEdit ? _handleSubmit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text('送信'),
            ),
          ],
        ),
      ],
    );
  }
}
