import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../config/supabase_config.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';
import 'auth_oauth_buttons.dart';

/// メール・パスワード・送信によるログイン（実装計画 Phase 5-2-1、詳細設計 4.2）。
///
/// OAuth は [AuthOAuthButtons]（Phase 5-2-3）。詳細バリデーション・[AuthNotifier] は後続タスク。
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
  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailFieldError(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    return null;
  }

  String? _passwordFieldError(String? value) {
    if ((value ?? '').isEmpty) {
      return 'パスワードを入力してください';
    }
    return null;
  }

  String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => 'ネットワークに接続できません。接続を確認してください。',
      AuthFailure() => 'メールアドレスまたはパスワードが正しくありません。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報の処理に失敗しました。',
    };
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    final useCase = ref.read(signInWithEmailUseCaseProvider);
    final result = await useCase(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        context.go(AppRoutePaths.feed);
      case Err(:final error):
        setState(() => _formError = _messageForFailure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            constraints: const BoxConstraints(maxWidth: AppTokens.bodyMaxLineWidth),
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
                      Semantics(
                        container: true,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'メールアドレス',
                            border: OutlineInputBorder(),
                          ),
                          validator: _emailFieldError,
                          enabled: !_submitting,
                        ),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      Semantics(
                        container: true,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                              onPressed: _submitting
                                  ? null
                                  : () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _passwordFieldError,
                          enabled: !_submitting,
                        ),
                      ),
                      if (_formError != null) ...[
                        SizedBox(height: AppTokens.spaceUnit * 2),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _formError!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppTokens.spaceUnit * 3),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('ログイン'),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 3),
                      AuthOAuthButtons(
                        enabled: !_submitting,
                        onError: (message) => setState(() => _formError = message),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => context.push(AppRoutePaths.signUp),
                        child: const Text('アカウントを作成'),
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
