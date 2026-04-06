import 'package:json_annotation/json_annotation.dart';

part 'rpc_feed_item_dto.g.dart';

String _rpcAuthorNameFromJson(Object? json) => (json as String?) ?? '';

int _intFromNum(Object? json) => (json as num).toInt();

double _doubleFromNum(Object? json) => (json as num).toDouble();

/// `get_local_feed` RPC の1行分の JSON 表現。
///
/// サーバの `RETURNS TABLE`（snake_case）とキーを揃える。
@JsonSerializable()
final class RpcFeedItemDto {
  const RpcFeedItemDto({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.locationLat,
    required this.locationLng,
    required this.createdAt,
    required this.expiresAt,
    required this.reactionCount,
    required this.authorName,
    required this.distanceMeters,
  });

  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  final String content;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'location_lat', fromJson: _doubleFromNum)
  final double locationLat;

  @JsonKey(name: 'location_lng', fromJson: _doubleFromNum)
  final double locationLng;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// `reaction_count`（bigint → JSON では number）
  @JsonKey(name: 'reaction_count', fromJson: _intFromNum)
  final int reactionCount;

  /// `author_name`（`profiles.name`、未設定時は空文字になり得る）
  @JsonKey(name: 'author_name', fromJson: _rpcAuthorNameFromJson)
  final String authorName;

  /// `distance_meters`（閲覧者クエリ地点からの距離・メートル）
  @JsonKey(name: 'distance_meters', fromJson: _doubleFromNum)
  final double distanceMeters;

  factory RpcFeedItemDto.fromJson(Map<String, dynamic> json) =>
      _$RpcFeedItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RpcFeedItemDtoToJson(this);
}
