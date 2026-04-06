import 'package:json_annotation/json_annotation.dart';

part 'rpc_post_detail_dto.g.dart';

String _rpcDetailAuthorNameFromJson(Object? json) => (json as String?) ?? '';

int _detailIntFromNum(Object? json) => (json as num).toInt();

double _detailDoubleFromNum(Object? json) => (json as num).toDouble();

/// `get_post_detail` RPC の戻り（1行）の JSON 表現。
@JsonSerializable()
final class RpcPostDetailDto {
  const RpcPostDetailDto({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.locationLat,
    required this.locationLng,
    required this.createdAt,
    required this.expiresAt,
    required this.reactionCount,
    required this.commentCount,
    required this.authorName,
    required this.distanceMeters,
  });

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String content;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'location_lat', fromJson: _detailDoubleFromNum)
  final double locationLat;

  @JsonKey(name: 'location_lng', fromJson: _detailDoubleFromNum)
  final double locationLng;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @JsonKey(name: 'reaction_count', fromJson: _detailIntFromNum)
  final int reactionCount;

  @JsonKey(name: 'comment_count', fromJson: _detailIntFromNum)
  final int commentCount;

  @JsonKey(name: 'author_name', fromJson: _rpcDetailAuthorNameFromJson)
  final String authorName;

  @JsonKey(name: 'distance_meters', fromJson: _detailDoubleFromNum)
  final double distanceMeters;

  factory RpcPostDetailDto.fromJson(Map<String, dynamic> json) =>
      _$RpcPostDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RpcPostDetailDtoToJson(this);
}
