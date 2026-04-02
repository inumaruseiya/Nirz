/// `comments` テーブル行の JSON 入出力用 DTO。
///
/// `user_id` はドメインの `Comment.authorId` に対応（Mapper で `UserId` に変換）。
final class CommentDto {
  const CommentDto({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;

  /// `comments.user_id`
  final String userId;

  /// `comments.parent_comment_id`
  final String? parentCommentId;

  final String content;
  final DateTime createdAt;

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'parent_comment_id': parentCommentId,
        'content': content,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
