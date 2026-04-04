import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// エラー文言 + 再試行ボタン（実装計画 Phase 6-3-4、詳細設計 5.1）。
class ErrorRetryPanel extends StatelessWidget {
  const ErrorRetryPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = '読み込めませんでした',
    this.retryLabel = '再試行',
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.bodyMaxLineWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceUnit * 3),
          child: Semantics(
            container: true,
            label: '$title。$message',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppTokens.spaceUnit * 2),
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spaceUnit),
                Text(
                  message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spaceUnit * 2),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
