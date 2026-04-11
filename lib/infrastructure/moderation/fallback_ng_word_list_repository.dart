import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/ng_word_list_repository.dart';

/// リモート取得に失敗したときだけ埋め込み一覧を返す（Phase 10-1-1）。
///
/// リモートが空リストを返す場合は「制限なし」とみなし、フォールバックしない。
final class FallbackNgWordListRepository implements NgWordListRepository {
  FallbackNgWordListRepository(this._remote, this._embedded);

  final NgWordListRepository _remote;
  final NgWordListRepository _embedded;

  @override
  Future<Result<List<String>, Failure>> loadNgWords() async {
    final remote = await _remote.loadNgWords();
    switch (remote) {
      case Ok(:final value):
        return Ok(value);
      case Err():
        return _embedded.loadNgWords();
    }
  }
}
