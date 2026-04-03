import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../config/supabase_config.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../infrastructure/providers.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';
import 'auth_oauth_buttons.dart';

/// メール・パスワード・ニックネームによる新規登録（実装計画 Phase 5-2-2、FR-AUTH-02）。
///
/// メール確認が有効なプロジェクトでは、登録後にセッションが無い場合は確認案内を表示する。
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _formError;
  bool _pendingEmailConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _nameFieldError(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'ニックネームを入力してください';
    }
    if (v.length > 50) {
      return 'ニックネームは50文字以内にしてください';
    }
    return null;
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

  String? _confirmPasswordFieldError(String? value) {
    if ((value ?? '').isEmpty) {
      return 'パスワード（確認）を入力してください';
    }
    if (value != _passwordController.text) {
      return 'パスワードが一致しません';
    }
    return null;
  }

  String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => 'ネットワークに接続できません。接続を確認してください。',
      AuthFailure() => '登録できませんでした。既に登録済みのメールアドレスの可能性があります。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報の処理に失敗しました。',
    };
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _pendingEmailConfirmation = false;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    final useCase = ref.read(signUpWithEmailUseCaseProvider);
    final result = await useCase(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    switch (result) {
      case Ok():
        final userId = await ref.read(authRepositoryProvider).getCurrentUserId();
        if (!mounted) {
          return;
        }
        if (userId != null) {
          context.go(AppRoutePaths.feed);
        } else {
          setState(() => _pendingEmailConfirmation = true);
        }
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
        appBar: AppBar(title: const Text('新規登録')),
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
      appBar: AppBar(title: const Text('新規登録')),
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
                      if (_pendingEmailConfirmation) ...[
                        Semantics(
                          liveRegion: true,
                          child: Material(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
                              child: Text(
                                '確認メールを送信しました。メール内のリンクを開いたあと、ログインしてください。',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppTokens.spaceUnit * 3),
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutePaths.login),
                          child: const Text('ログイン画面へ'),
                        ),
                        SizedBox(height: AppTokens.spaceUnit * 2),
                      ],
                      Semantics(
                        container: true,
                        child: TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'ニックネーム',
                            border: OutlineInputBorder(),
                          ),
                          validator: _nameFieldError,
                          enabled: !_submitting && !_pendingEmailConfirmation,
                        ),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
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
                          enabled: !_submitting && !_pendingEmailConfirmation,
                        ),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      Semantics(
                        container: true,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'パスワード',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                              onPressed: _submitting || _pendingEmailConfirmation
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
                          enabled: !_submitting && !_pendingEmailConfirmation,
                          onChanged: (_) {
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _formKey.currentState?.validate();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      Semantics(
                        container: true,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'パスワード（確認）',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm ? 'パスワードを表示' : 'パスワードを隠す',
                              onPressed: _submitting || _pendingEmailConfirmation
                                  ? null
                                  : () => setState(
                                        () => _obscureConfirm = !_obscureConfirm,
                                      ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _confirmPasswordFieldError,
                          enabled: !_submitting && !_pendingEmailConfirmation,
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
                      if (!_pendingEmailConfirmation) ...[
                        SizedBox(height: AppTokens.spaceUnit * 3),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('登録する'),
                        ),
                        SizedBox(height: AppTokens.spaceUnit * 3),
                        AuthOAuthButtons(
                          enabled: !_submitting && !_pendingEmailConfirmation,
                          onError: (message) => setState(() => _formError = message),
                        ),
                      ],
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => context.go(AppRoutePaths.login),
                        child: const Text('すでにアカウントをお持ちの方はログイン'),
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
