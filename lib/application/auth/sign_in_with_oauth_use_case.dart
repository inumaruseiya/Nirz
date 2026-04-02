import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';

final class SignInWithOAuthUseCase {
  SignInWithOAuthUseCase(this._auth);

  final AuthRepository _auth;

  Future<Result<void, Failure>> call(AuthOAuthProvider provider) {
    return _auth.signInWithOAuth(provider);
  }
}
