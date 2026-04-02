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

  Future<Result<void, Failure>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<void, Failure>> signInWithOAuth(AuthOAuthProvider provider);

  Future<Result<void, Failure>> signOut();

  /// 現在のセッションに紐づくユーザー ID。未サインイン時は null。
  Future<UserId?> getCurrentUserId();
}
