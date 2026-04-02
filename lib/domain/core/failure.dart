/// ドメイン層で扱う失敗の閉じた集合（Presentation ではユーザー向け文言に変換する）。
sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class AuthFailure extends Failure {
  const AuthFailure();
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.message);

  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class LocationFailure extends Failure {
  const LocationFailure();
}
