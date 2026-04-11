import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../infrastructure/providers.dart';

/// メールによるログイン／登録の UI 状態（実装計画 Phase 5-2-5、詳細設計 5）。
sealed class AuthState {
  const AuthState();
}

/// 入力可能。初期状態および成功遷移後に [AuthNotifier.reset] で戻す。
final class AuthIdle extends AuthState {
  const AuthIdle();
}

/// 送信中。
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// メールフロー成功。新規登録でメール確認のみのとき [awaitingEmailConfirmation] が true。
final class AuthSuccess extends AuthState {
  const AuthSuccess({this.awaitingEmailConfirmation = false});

  final bool awaitingEmailConfirmation;
}

/// API 失敗など。文言はユーザー向け。
final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

/// ログイン・新規登録フォーム用（[autoDispose] で画面を離れたら破棄しやすくする）。
final class AuthNotifier extends AutoDisposeNotifier<AuthState> {
  @override
  AuthState build() => const AuthIdle();

  void reset() => state = const AuthIdle();

  void setError(String message) => state = AuthError(message);

  void clearError() {
    if (state is AuthError) {
      state = const AuthIdle();
    }
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

  String _messageForSignUpFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => 'ネットワークに接続できません。接続を確認してください。',
      AuthFailure() => '登録できませんでした。既に登録済みのメールアドレスの可能性があります。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報の処理に失敗しました。',
    };
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final useCase = ref.read(signInWithEmailUseCaseProvider);
    final result = await useCase(email: email, password: password);
    switch (result) {
      case Ok():
        state = const AuthSuccess();
      case Err(:final error):
        state = AuthError(_messageForFailure(error));
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AuthLoading();
    final useCase = ref.read(signUpWithEmailUseCaseProvider);
    final result = await useCase(
      email: email,
      password: password,
      displayName: displayName,
    );
    switch (result) {
      case Ok():
        final userId = await ref
            .read(authRepositoryProvider)
            .getCurrentUserId();
        state = AuthSuccess(awaitingEmailConfirmation: userId == null);
      case Err(:final error):
        state = AuthError(_messageForSignUpFailure(error));
    }
  }
}

/// ログイン画面専用（新規登録画面と状態を分離）。
final loginAuthNotifierProvider =
    NotifierProvider.autoDispose<AuthNotifier, AuthState>(AuthNotifier.new);

/// 新規登録画面専用。
final signUpAuthNotifierProvider =
    NotifierProvider.autoDispose<AuthNotifier, AuthState>(AuthNotifier.new);
