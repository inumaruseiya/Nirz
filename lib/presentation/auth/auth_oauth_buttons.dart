import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../theme/app_tokens.dart';

/// Google / Apple の OAuth サインイン（実装計画 Phase 5-2-3）。
///
/// ブラウザ／システム UI に遷移する。戻り後のセッションは [GoRouter] の認証リフレッシュで反映される。
class AuthOAuthButtons extends ConsumerStatefulWidget {
  const AuthOAuthButtons({super.key, required this.enabled, this.onError});

  /// メールフォーム送信中などは false にする。
  final bool enabled;

  /// OAuth 失敗時にメッセージを渡す。null でクリア。
  final void Function(String? message)? onError;

  @override
  ConsumerState<AuthOAuthButtons> createState() => _AuthOAuthButtonsState();
}

class _AuthOAuthButtonsState extends ConsumerState<AuthOAuthButtons> {
  AuthOAuthProvider? _busyProvider;

  bool get _interactive => widget.enabled && _busyProvider == null;

  String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => 'ネットワークに接続できません。接続を確認してください。',
      AuthFailure() => 'サインインを開始できませんでした。もう一度お試しください。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報の処理に失敗しました。',
    };
  }

  Future<void> _startOAuth(AuthOAuthProvider provider) async {
    if (!_interactive) {
      return;
    }
    setState(() => _busyProvider = provider);
    widget.onError?.call(null);

    final useCase = ref.read(signInWithOAuthUseCaseProvider);
    final result = await useCase(provider);

    if (!mounted) {
      return;
    }
    setState(() => _busyProvider = null);

    switch (result) {
      case Ok():
        break;
      case Err(:final error):
        widget.onError?.call(_messageForFailure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(height: 1, color: scheme.outlineVariant)),
            Semantics(
              label: '区切り。または',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceUnit * 2,
                ),
                child: Text(
                  'または',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(child: Divider(height: 1, color: scheme.outlineVariant)),
          ],
        ),
        SizedBox(height: AppTokens.spaceUnit * 2),
        OutlinedButton.icon(
          onPressed: widget.enabled && _busyProvider == null
              ? () => _startOAuth(AuthOAuthProvider.google)
              : null,
          icon: _busyProvider == AuthOAuthProvider.google
              ? Semantics(
                  label: 'Googleでサインイン処理中',
                  excludeSemantics: true,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.account_circle_outlined, semanticLabel: ''),
          label: const Text('Googleで続行'),
        ),
        SizedBox(height: AppTokens.spaceUnit * 2),
        OutlinedButton.icon(
          onPressed: widget.enabled && _busyProvider == null
              ? () => _startOAuth(AuthOAuthProvider.apple)
              : null,
          icon: _busyProvider == AuthOAuthProvider.apple
              ? Semantics(
                  label: 'Appleでサインイン処理中',
                  excludeSemantics: true,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.apple, semanticLabel: ''),
          label: const Text('Appleで続行'),
        ),
      ],
    );
  }
}
