// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rpc_post_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RpcPostDetailDto _$RpcPostDetailDtoFromJson(Map<String, dynamic> json) =>
    RpcPostDetailDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: _detailDoubleFromNum(json['location_lat']),
      locationLng: _detailDoubleFromNum(json['location_lng']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      reactionCount: _detailIntFromNum(json['reaction_count']),
      commentCount: _detailIntFromNum(json['comment_count']),
      authorName: _rpcDetailAuthorNameFromJson(json['author_name']),
      distanceMeters: _detailDoubleFromNum(json['distance_meters']),
    );

Map<String, dynamic> _$RpcPostDetailDtoToJson(RpcPostDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'content': instance.content,
      'image_url': instance.imageUrl,
      'location_lat': instance.locationLat,
      'location_lng': instance.locationLng,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'reaction_count': instance.reactionCount,
      'comment_count': instance.commentCount,
      'author_name': instance.authorName,
      'distance_meters': instance.distanceMeters,
    };
