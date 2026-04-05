import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/reaction.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../../domain/value_objects/post_id.dart';

final class GetMyReactionUseCase {
  GetMyReactionUseCase(this._reactions);

  final ReactionRepository _reactions;

  Future<Result<Reaction?, Failure>> call(PostId postId) {
    return _reactions.getMyReaction(postId);
  }
}
