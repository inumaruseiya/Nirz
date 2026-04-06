import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/repositories/ng_word_list_repository.dart';
import '../../domain/services/ng_word_moderation.dart';
import '../../domain/value_objects/post_id.dart';

final class AddCommentUseCase {
  AddCommentUseCase(
    this._comments,
    this._ngWords,
  );

  final CommentRepository _comments;
  final NgWordListRepository _ngWords;

  Future<Result<Comment, Failure>> call({
    required PostId postId,
    required String content,
  }) async {
    final wordsResult = await _ngWords.loadNgWords();
    switch (wordsResult) {
      case Ok(:final value):
        final ngFail = ngWordValidationFailure(content, value);
        if (ngFail != null) {
          return Err(ngFail);
        }
      case Err(:final error):
        return Err(error);
    }
    return _comments.addComment(postId: postId, content: content);
  }
}
