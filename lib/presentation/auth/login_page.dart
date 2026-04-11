import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../config/supabase_config.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';
import 'auth_field_validators.dart';
import 'auth_notifier.dart';
import 'auth_oauth_buttons.dart';

/// メール・パスワード・送信によるログイン（実装計画 Phase 5-2-1、詳細設計 4.2）。
///
/// 送信中・結果は [loginAuthNotifierProvider]（Phase 5-2-5）。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailFieldError(String? value) => AuthFieldValidators.email(value);

  String? _passwordFieldError(String? value) =>
      AuthFieldValidators.password(value);

  String _messageForResetFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => 'ネットワークに接続できません。接続を確認してください。',
      AuthFailure() => '送信できませんでした。メールアドレスを確認してください。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報の処理に失敗しました。',
    };
  }

  Future<void> _showPasswordResetDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PasswordResetDialog(
        initialEmail: _emailController.text.trim(),
        messageForFailure: _messageForResetFailure,
        onSent: () {
          messenger.showSnackBar(
            const SnackBar(content: Text('再設定用のメールを送信しました。受信トレイをご確認ください。')),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(loginAuthNotifierProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AuthState>(loginAuthNotifierProvider, (previous, next) {
      if (next is AuthSuccess && !next.awaitingEmailConfirmation) {
        context.go(AppRoutePaths.feed);
      }
    });

    final authState = ref.watch(loginAuthNotifierProvider);
    final loading = authState is AuthLoading;
    final formError = switch (authState) {
      AuthError(:final message) => message,
      _ => null,
    };

    if (!SupabaseConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('ログイン')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceUnit * 3),
              child: Text(
                'Supabase を --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY で設定してください。.env.example を参照してください。',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTokens.bodyMaxLineWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceUnit * 3,
                vertical: AppTokens.spaceUnit * 2,
              ),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          border: OutlineInputBorder(),
                          hintText: 'example@email.com',
                        ),
                        validator: _emailFieldError,
                        enabled: !loading,
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          helperText:
                              '${AuthFieldValidators.passwordMinLength}文字以上',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                            onPressed: loading
                                ? null
                                : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              semanticLabel: _obscurePassword
                                  ? 'パスワードは隠されています'
                                  : 'パスワードは表示されています',
                            ),
                          ),
                        ),
                        validator: _passwordFieldError,
                        enabled: !loading,
                      ),
                      if (formError != null) ...[
                        SizedBox(height: AppTokens.spaceUnit * 2),
                        Semantics(
                          liveRegion: true,
                          label: 'エラー。$formError',
                          excludeSemantics: true,
                          child: Text(
                            formError,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppTokens.spaceUnit * 3),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? Semantics(
                                label: 'ログイン処理中',
                                excludeSemantics: true,
                                child: const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Text('ログイン'),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 3),
                      AuthOAuthButtons(
                        enabled: !loading,
                        onError: (message) {
                          final n = ref.read(
                            loginAuthNotifierProvider.notifier,
                          );
                          if (message == null) {
                            n.clearError();
                          } else {
                            n.setError(message);
                          }
                        },
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      Tooltip(
                        message: '新規登録の画面を開きます',
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  ref
                                      .read(loginAuthNotifierProvider.notifier)
                                      .reset();
                                  context.push(AppRoutePaths.signUp);
                                },
                          child: const Text('アカウントを作成'),
                        ),
                      ),
                      Center(
                        child: Tooltip(
                          message: 'メールアドレス宛にパスワード再設定用のリンクを送ります',
                          child: TextButton(
                            onPressed: loading
                                ? null
                                : _showPasswordResetDialog,
                            child: const Text('パスワードをお忘れの方'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// パスワード再設定メール送信（Phase 5-2-6）。
class _PasswordResetDialog extends ConsumerStatefulWidget {
  const _PasswordResetDialog({
    required this.initialEmail,
    required this.messageForFailure,
    required this.onSent,
  });

  final String initialEmail;
  final String Function(Failure) messageForFailure;
  final VoidCallback onSent;

  @override
  ConsumerState<_PasswordResetDialog> createState() =>
      _PasswordResetDialogState();
}

class _PasswordResetDialogState extends ConsumerState<_PasswordResetDialog> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _sending = true);
    final useCase = ref.read(requestPasswordResetUseCaseProvider);
    final result = await useCase(email: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
        widget.onSent();
      case Err(:final error):
        setState(() => _error = widget.messageForFailure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('パスワード再設定'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '登録したメールアドレスに、パスワード再設定用のリンクを送ります。',
                style: textTheme.bodyMedium,
              ),
              SizedBox(height: AppTokens.spaceUnit * 2),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  hintText: 'example@email.com',
                ),
                validator: AuthFieldValidators.email,
                enabled: !_sending,
              ),
              if (_error != null) ...[
                SizedBox(height: AppTokens.spaceUnit * 2),
                Semantics(
                  liveRegion: true,
                  label: 'エラー。$_error',
                  excludeSemantics: true,
                  child: Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? Semantics(
                  label: '送信中',
                  excludeSemantics: true,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Text('送信'),
        ),
      ],
    );
  }
}
