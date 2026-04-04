import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_tokens.dart';
import 'compose_notifier.dart';

/// 全画面モーダル（`fullscreenDialog`）で表示する投稿作成画面。
///
/// 詳細設計 4.4: 本文入力・任意画像・位置ぼかし後の送信。
class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({super.key});

  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<ComposePage> {
  static const int _maxContentLength = 2000;

  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _contentValid =>
      _contentController.text.trim().isNotEmpty;

  bool _canSubmit(ComposeState composeState) {
    if (composeState is! ComposeEditing) return false;
    return composeState.locationReady && _contentValid;
  }

  bool _inputsLocked(ComposeState s) =>
      s is ComposeObfuscating || s is ComposeSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final composeState = ref.watch(composeNotifierProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _inputsLocked(composeState)
              ? null
              : () => context.pop(),
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
                  AppTokens.spaceUnit,
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
                        readOnly: _inputsLocked(composeState),
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
            _ComposeStatusStrip(
              state: composeState,
              onDismissFailure: () => ref
                  .read(composeNotifierProvider.notifier)
                  .dismissFailure(),
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
                          onPressed: _inputsLocked(composeState)
                              ? null
                              : _onAddImagePressed,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('画像を追加'),
                        ),
                        const SizedBox(height: AppTokens.spaceUnit),
                        FilledButton.icon(
                          onPressed: _canSubmit(composeState)
                              ? _onSubmitPressed
                              : null,
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

  void _onAddImagePressed() {
    // Phase 7-1-4: image_picker 接続
  }

  void _onSubmitPressed() {
    // Phase 7-1-7: notifier.startSubmit() → CreatePostUseCase →
    // markSubmitSuccess / markSubmitFailure
  }
}

class _ComposeStatusStrip extends StatelessWidget {
  const _ComposeStatusStrip({
    required this.state,
    required this.onDismissFailure,
  });

  final ComposeState state;
  final VoidCallback onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return switch (state) {
      ComposeEditing(:final locationReady) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceUnit * 2,
            vertical: AppTokens.spaceUnit,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTokens.bodyMaxLineWidth,
              ),
              child: Text(
                locationReady
                    ? '位置の準備ができました。内容を確認して送信できます。'
                    : '位置情報の確認が完了すると送信ボタンが有効になります。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ComposeObfuscating() => Material(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceUnit * 2,
              vertical: AppTokens.spaceUnit * 1.5,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTokens.spaceUnit * 2),
                Expanded(
                  child: Text(
                    '位置を準備しています',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ComposeSubmitting() => const SizedBox.shrink(),
      ComposeSuccess() => Material(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceUnit * 2,
              vertical: AppTokens.spaceUnit * 1.5,
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colorScheme.primary),
                const SizedBox(width: AppTokens.spaceUnit * 2),
                Expanded(
                  child: Text(
                    '投稿が完了しました',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ComposeFailure(:final message) => Material(
          color: colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceUnit * 2,
              AppTokens.spaceUnit * 1.5,
              AppTokens.spaceUnit,
              AppTokens.spaceUnit * 1.5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppTokens.spaceUnit * 2),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onDismissFailure,
                  child: const Text('閉じる'),
                ),
              ],
            ),
          ),
        ),
    };
  }
}
