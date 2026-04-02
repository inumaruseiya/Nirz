/// ユースケース等の戻り値用の結果型。
///
/// 実装計画では成功/失敗を Success / Failure と書いているが、
/// ドメインの `Failure`（failure.dart）と名前が衝突するため失敗側は [Err] とする。
sealed class Result<T, E> {
  const Result._();
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value) : super._();

  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error) : super._();

  final E error;
}
