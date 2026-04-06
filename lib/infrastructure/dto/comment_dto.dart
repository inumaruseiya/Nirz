import 'package:json_annotation/json_annotation.dart';

part 'comment_dto.g.dart';

/// `comments` テーブル行の JSON 入出力用 DTO。
///
/// `user_id` はドメインの `Comment.authorId` に対応（Mapper で `UserId` に変換）。
@JsonSerializable()
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

  @JsonKey(name: 'post_id')
  final String postId;

  /// `comments.user_id`
  @JsonKey(name: 'user_id')
  final String userId;

  /// `comments.parent_comment_id`
  @JsonKey(name: 'parent_comment_id')
  final String? parentCommentId;

  final String content;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory CommentDto.fromJson(Map<String, dynamic> json) =>
      _$CommentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CommentDtoToJson(this);
}
