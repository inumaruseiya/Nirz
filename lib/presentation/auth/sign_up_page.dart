import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/supabase_config.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';
import 'auth_field_validators.dart';
import 'auth_notifier.dart';
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

  String? _emailFieldError(String? value) => AuthFieldValidators.email(value);

  String? _passwordFieldError(String? value) =>
      AuthFieldValidators.password(value);

  String? _confirmPasswordFieldError(String? value) {
    if ((value ?? '').isEmpty) {
      return 'パスワード（確認）を入力してください';
    }
    if (value != _passwordController.text) {
      return 'パスワードが一致しません';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(signUpAuthNotifierProvider.notifier).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<AuthState>(signUpAuthNotifierProvider, (previous, next) {
      if (next is AuthSuccess && !next.awaitingEmailConfirmation) {
        context.go(AppRoutePaths.feed);
      }
    });

    final authState = ref.watch(signUpAuthNotifierProvider);
    final loading = authState is AuthLoading;
    final formError = switch (authState) {
      AuthError(:final message) => message,
      _ => null,
    };
    final pendingEmail = switch (authState) {
      AuthSuccess(awaitingEmailConfirmation: true) => true,
      _ => false,
    };

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
                      if (pendingEmail) ...[
                        Semantics(
                          liveRegion: true,
                          label:
                              '確認メールを送信しました。メール内のリンクを開いたあと、ログインしてください。',
                          excludeSemantics: true,
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
                          onPressed: () {
                            ref.read(signUpAuthNotifierProvider.notifier).reset();
                            context.go(AppRoutePaths.login);
                          },
                          child: const Text('ログイン画面へ'),
                        ),
                        SizedBox(height: AppTokens.spaceUnit * 2),
                      ],
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'ニックネーム',
                          border: OutlineInputBorder(),
                        ),
                        validator: _nameFieldError,
                        enabled: !loading && !pendingEmail,
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
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
                        enabled: !loading && !pendingEmail,
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'パスワード',
                          helperText:
                              '${AuthFieldValidators.passwordMinLength}文字以上',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                            onPressed: loading || pendingEmail
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
                        enabled: !loading && !pendingEmail,
                        onChanged: (_) {
                          if (_confirmPasswordController.text.isNotEmpty) {
                            _formKey.currentState?.validate();
                          }
                        },
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextFormField(
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
                            onPressed: loading || pendingEmail
                                ? null
                                : () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              semanticLabel: _obscureConfirm
                                  ? '確認用パスワードは隠されています'
                                  : '確認用パスワードは表示されています',
                            ),
                          ),
                        ),
                        validator: _confirmPasswordFieldError,
                        enabled: !loading && !pendingEmail,
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
                      if (!pendingEmail) ...[
                        SizedBox(height: AppTokens.spaceUnit * 3),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? Semantics(
                                  label: '登録処理中',
                                  excludeSemantics: true,
                                  child: const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const Text('登録する'),
                        ),
                        SizedBox(height: AppTokens.spaceUnit * 3),
                        AuthOAuthButtons(
                          enabled: !loading && !pendingEmail,
                          onError: (message) {
                            final n = ref.read(signUpAuthNotifierProvider.notifier);
                            if (message == null) {
                              n.clearError();
                            } else {
                              n.setError(message);
                            }
                          },
                        ),
                      ],
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      Tooltip(
                        message: 'ログイン画面に移動します',
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  ref
                                      .read(signUpAuthNotifierProvider.notifier)
                                      .reset();
                                  context.go(AppRoutePaths.login);
                                },
                          child: const Text('すでにアカウントをお持ちの方はログイン'),
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
