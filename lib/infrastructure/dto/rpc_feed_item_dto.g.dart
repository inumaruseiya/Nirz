// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rpc_feed_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RpcFeedItemDto _$RpcFeedItemDtoFromJson(Map<String, dynamic> json) =>
    RpcFeedItemDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: _doubleFromNum(json['location_lat']),
      locationLng: _doubleFromNum(json['location_lng']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      reactionCount: _intFromNum(json['reaction_count']),
      authorName: _rpcAuthorNameFromJson(json['author_name']),
      distanceMeters: _doubleFromNum(json['distance_meters']),
    );

Map<String, dynamic> _$RpcFeedItemDtoToJson(RpcFeedItemDto instance) =>
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
      'author_name': instance.authorName,
      'distance_meters': instance.distanceMeters,
    };
