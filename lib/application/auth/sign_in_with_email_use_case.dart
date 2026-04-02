import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';

final class SignInWithEmailUseCase {
  SignInWithEmailUseCase(this._auth);

  final AuthRepository _auth;

  Future<Result<void, Failure>> call({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmail(email: email, password: password);
  }
}
