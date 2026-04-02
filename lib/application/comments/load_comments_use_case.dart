import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/value_objects/post_id.dart';

final class LoadCommentsUseCase {
  LoadCommentsUseCase(this._comments);

  final CommentRepository _comments;

  Future<Result<List<Comment>, Failure>> call(PostId postId) {
    return _comments.listByPost(postId);
  }
}
