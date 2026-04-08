import '../core/failure.dart';
import '../core/result.dart';
import '../value_objects/user_id.dart';

/// ユーザーブロックの永続化（実装計画 Phase 10-3-2、FR-MOD-03）。
abstract interface class BlockRepository {
  /// 現在ユーザーが [blockedUserId] をブロックする行を追加する。
  Future<Result<void, Failure>> addBlock(UserId blockedUserId);
}
