import '../../domain/entities/comment.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../dto/comment_dto.dart';

/// [CommentDto] → [Comment]
final class CommentMapper {
  const CommentMapper._();

  static Comment toDomain(CommentDto dto) {
    return Comment(
      id: CommentId.parse(dto.id),
      postId: PostId.parse(dto.postId),
      authorId: UserId.parse(dto.userId),
      parentId: dto.parentCommentId != null
          ? CommentId.parse(dto.parentCommentId!)
          : null,
      content: dto.content,
      createdAt: dto.createdAt,
    );
  }
}
