import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';

final class RequestPasswordResetUseCase {
  RequestPasswordResetUseCase(this._auth);

  final AuthRepository _auth;

  Future<Result<void, Failure>> call({required String email}) {
    return _auth.requestPasswordReset(email: email);
  }
}
