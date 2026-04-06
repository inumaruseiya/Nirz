// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => CommentDto(
  id: json['id'] as String,
  postId: json['post_id'] as String,
  userId: json['user_id'] as String,
  parentCommentId: json['parent_comment_id'] as String?,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CommentDtoToJson(CommentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post_id': instance.postId,
      'user_id': instance.userId,
      'parent_comment_id': instance.parentCommentId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
    };
