import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../../domain/value_objects/post_id.dart';

final class RemoveReactionUseCase {
  RemoveReactionUseCase(this._reactions);

  final ReactionRepository _reactions;

  Future<Result<void, Failure>> call(PostId postId) {
    return _reactions.removeReaction(postId);
  }
}
