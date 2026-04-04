import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';

/// 全画面モーダル（`fullscreenDialog`）で表示する投稿作成画面。
///
/// 詳細設計 4.4: 本文入力・任意画像・位置ぼかし後の送信。レイアウトは Phase 7-1-1、
/// 状態・バリデーション・送信は後続タスクで接続する。
class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  static const int _maxContentLength = 2000;

  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: '閉じる',
        ),
        title: const Text('投稿を作成'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit,
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit * 2,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.bodyMaxLineWidth,
                    ),
                    child: Semantics(
                      label: '投稿本文',
                      textField: true,
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: '近くの出来事や気持ちを書いてください',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 6,
                        maxLines: 12,
                        maxLength: _maxContentLength,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          return Text(
                            '$currentLength / $maxLength',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              elevation: 2,
              shadowColor: theme.shadowColor.withValues(alpha: 0.12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit * 1.5,
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit * 1.5 + bottomInset,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.bodyMaxLineWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _onAddImagePressed,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('画像を追加'),
                        ),
                        const SizedBox(height: AppTokens.spaceUnit),
                        FilledButton.icon(
                          onPressed: _canSubmitShell ? _onSubmitPressed : null,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('送信'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// シェル段階では常に無効（Phase 7-1-5 以降で位置ぼかし成功後に有効化）。
  bool get _canSubmitShell => false;

  void _onAddImagePressed() {
    // Phase 7-1-4: image_picker 接続
  }

  void _onSubmitPressed() {
    // Phase 7-1-7: CreatePostUseCase 接続
  }
}
