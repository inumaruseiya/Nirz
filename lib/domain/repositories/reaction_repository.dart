import '../core/failure.dart';
import '../core/result.dart';
import '../entities/reaction.dart';
import '../value_objects/post_id.dart';
import '../value_objects/reaction_type.dart';

/// リアクションの UPSERT / 削除 / 自分のリアクション取得（1ユーザー1投稿1種）。
abstract interface class ReactionRepository {
  Future<Result<void, Failure>> upsertReaction(
    PostId postId,
    ReactionType type,
  );

  Future<Result<void, Failure>> removeReaction(PostId postId);

  /// 未リアクションのときは成功かつ値 null。
  Future<Result<Reaction?, Failure>> getMyReaction(PostId postId);
}
