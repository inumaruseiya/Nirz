import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';

final class SignUpWithEmailUseCase {
  SignUpWithEmailUseCase(this._auth);

  final AuthRepository _auth;

  Future<Result<void, Failure>> call({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _auth.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
