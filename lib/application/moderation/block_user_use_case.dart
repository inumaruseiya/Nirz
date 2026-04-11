import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/block_repository.dart';
import '../../domain/value_objects/user_id.dart';

/// 自分以外のユーザーをブロックする（Phase 10-3-2）。
final class BlockUserUseCase {
  BlockUserUseCase(this._blocks, this._auth);

  final BlockRepository _blocks;
  final AuthRepository _auth;

  Future<Result<void, Failure>> call(UserId blockedUserId) async {
    final self = await _auth.getCurrentUserId();
    if (self == null) {
      return const Err(AuthFailure());
    }
    if (self.value == blockedUserId.value) {
      return const Err(ValidationFailure('自分自身はブロックできません。'));
    }
    return _blocks.addBlock(blockedUserId);
  }
}
