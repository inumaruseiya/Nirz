import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/supabase_config.dart';
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(loginAuthNotifierProvider.notifier).signInWithEmail(
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
                            hintText: 'example@email.com',
                          ),
                          validator: _emailFieldError,
                          enabled: !loading,
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
                              ),
                            ),
                          ),
                          validator: _passwordFieldError,
                          enabled: !loading,
                        ),
                      ),
                      if (formError != null) ...[
                        SizedBox(height: AppTokens.spaceUnit * 2),
                        Semantics(
                          liveRegion: true,
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
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('ログイン'),
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 3),
                      AuthOAuthButtons(
                        enabled: !loading,
                        onError: (message) {
                          final n = ref.read(loginAuthNotifierProvider.notifier);
                          if (message == null) {
                            n.clearError();
                          } else {
                            n.setError(message);
                          }
                        },
                      ),
                      SizedBox(height: AppTokens.spaceUnit * 2),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                ref.read(loginAuthNotifierProvider.notifier).reset();
                                context.push(AppRoutePaths.signUp);
                              },
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
