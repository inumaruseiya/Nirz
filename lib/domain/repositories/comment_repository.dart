import '../core/failure.dart';
import '../core/result.dart';
import '../entities/comment.dart';
import '../value_objects/comment_id.dart';
import '../value_objects/post_id.dart';

/// コメント一覧・トップレベル投稿・1階層返信（返信の検証はユースケースで行う）。
abstract interface class CommentRepository {
  Future<Result<List<Comment>, Failure>> listByPost(PostId postId);

  Future<Result<Comment, Failure>> addComment({
    required PostId postId,
    required String content,
  });

  /// [parentId] はトップレベルコメントの ID（`parentId == null` の行への返信のみ許可するのは Application 層）。
  Future<Result<Comment, Failure>> addReply({
    required PostId postId,
    required CommentId parentId,
    required String content,
  });
}
