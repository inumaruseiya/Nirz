import '../core/failure.dart';
import '../core/result.dart';
import '../value_objects/user_id.dart';

/// 認証セッションのスナップショット（[AuthRepository.watchSession] の要素型）。
sealed class SessionState {
  const SessionState();
}

final class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

final class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.userId);

  final UserId userId;
}

/// OAuth サインインで扱うプロバイダ（Infrastructure で Supabase のプロバイダにマップする）。
enum AuthOAuthProvider {
  google,
  apple,
}

/// 認証の抽象。Supabase Auth の具象は Infrastructure に置く。
abstract interface class AuthRepository {
  Stream<SessionState> watchSession();

  /// サーバと通信してセッションを更新する（オフライン検知・スプラッシュ再試行用）。
  ///
  /// 未サインインやトークン無効は [AuthFailure] になり得る。呼び出し側は必要なら続けて [watchSession] を参照する。
  Future<Result<void, Failure>> refreshAuthSession();

  Future<Result<void, Failure>> signInWithEmail({
    required String email,
    required String password,
  });

  /// 新規登録。表示名は `profiles.name` 用に `raw_user_meta_data.name` へ渡す（`handle_new_user` トリガと整合）。
  Future<Result<void, Failure>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Result<void, Failure>> signInWithOAuth(AuthOAuthProvider provider);

  Future<Result<void, Failure>> signOut();

  /// 現在のセッションに紐づくユーザー ID。未サインイン時は null。
  Future<UserId?> getCurrentUserId();
}
