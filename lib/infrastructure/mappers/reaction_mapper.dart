import '../../domain/entities/reaction.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/reaction_type.dart';
import '../../domain/value_objects/user_id.dart';
import '../dto/reaction_dto.dart';

/// [ReactionDto] → [Reaction]
final class ReactionMapper {
  const ReactionMapper._();

  static Reaction toDomain(ReactionDto dto) {
    return Reaction(
      userId: UserId.parse(dto.userId),
      postId: PostId.parse(dto.postId),
      type: ReactionType.parse(dto.type),
      createdAt: dto.createdAt,
    );
  }
}
