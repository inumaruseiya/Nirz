// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) => ProfileDto(
  id: json['id'] as String,
  displayName: _profileDisplayNameFromJson(json['name']),
  avatarUrl: json['avatar_url'] as String?,
  presenceStatus: json['presence_status'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ProfileDtoToJson(ProfileDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'presence_status': instance.presenceStatus,
      'created_at': instance.createdAt.toIso8601String(),
    };
