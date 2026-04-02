import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';

final class SignOutUseCase {
  SignOutUseCase(this._auth);

  final AuthRepository _auth;

  Future<Result<void, Failure>> call() => _auth.signOut();
}
