import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/reaction_repository.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/reaction_type.dart';

final class SubmitReactionUseCase {
  SubmitReactionUseCase(this._reactions);

  final ReactionRepository _reactions;

  Future<Result<void, Failure>> call(PostId postId, ReactionType type) {
    return _reactions.upsertReaction(postId, type);
  }
}
