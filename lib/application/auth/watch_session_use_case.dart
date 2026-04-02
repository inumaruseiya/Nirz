import '../../domain/repositories/auth_repository.dart';

final class WatchSessionUseCase {
  WatchSessionUseCase(this._auth);

  final AuthRepository _auth;

  Stream<SessionState> call() => _auth.watchSession();
}
