import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/value_objects/post_id.dart';

final class AddCommentUseCase {
  AddCommentUseCase(this._comments);

  final CommentRepository _comments;

  Future<Result<Comment, Failure>> call({
    required PostId postId,
    required String content,
  }) {
    return _comments.addComment(postId: postId, content: content);
  }
}
