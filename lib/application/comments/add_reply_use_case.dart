import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/post_id.dart';

/// 1階層返信のみ。[parentId] はトップレベルコメント（`parentId == null`）であること。
final class AddReplyUseCase {
  AddReplyUseCase(this._comments);

  final CommentRepository _comments;

  Future<Result<Comment, Failure>> call({
    required PostId postId,
    required CommentId parentId,
    required String content,
  }) async {
    final listResult = await _comments.listByPost(postId);
    switch (listResult) {
      case Ok(:final value):
        Comment? parent;
        for (final c in value) {
          if (c.id == parentId) {
            parent = c;
            break;
          }
        }
        if (parent == null) {
          return const Err(
            ValidationFailure('対象のコメントが見つかりません。'),
          );
        }
        if (!parent.isTopLevelComment) {
          return const Err(
            ValidationFailure(
              '返信の返信はできません。トップレベルのコメントにのみ返信できます。',
            ),
          );
        }
        return _comments.addReply(
          postId: postId,
          parentId: parentId,
          content: content,
        );
      case Err(:final error):
        return Err(error);
    }
  }
}
