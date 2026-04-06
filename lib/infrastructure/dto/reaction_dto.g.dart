// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReactionDto _$ReactionDtoFromJson(Map<String, dynamic> json) => ReactionDto(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  postId: json['post_id'] as String,
  type: json['type'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ReactionDtoToJson(ReactionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'post_id': instance.postId,
      'type': instance.type,
      'created_at': instance.createdAt.toIso8601String(),
    };
