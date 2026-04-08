import '../core/failure.dart';
import '../core/result.dart';

/// NG ワード一覧の取得（実装計画 Phase 10-1-1）。
///
/// サーバ（Supabase）を正とし、取得失敗時は埋め込みリストへフォールバックする実装を想定する。
abstract interface class NgWordListRepository {
  Future<Result<List<String>, Failure>> loadNgWords();
}
