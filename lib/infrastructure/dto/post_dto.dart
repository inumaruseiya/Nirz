import 'package:json_annotation/json_annotation.dart';

part 'post_dto.g.dart';

/// PostgREST / Supabase の `geography(Point)` が GeoJSON として返るときの入れ子表現。
///
/// `coordinates` は **\[経度, 緯度\]**（RFC 7946）順。
final class GeoJsonLocation {
  const GeoJsonLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory GeoJsonLocation.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType != 'Point') {
      throw FormatException('location.type must be Point', rawType);
    }
    final coords = json['coordinates'];
    if (coords is! List || coords.length < 2) {
      throw FormatException('location.coordinates must be [lng, lat]', coords);
    }
    return GeoJsonLocation(
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      };
}

GeoJsonLocation _postLocationFromJson(Object? json) {
  if (json is! Map<String, dynamic>) {
    throw FormatException('location must be a GeoJSON object', json);
  }
  return GeoJsonLocation.fromJson(json);
}

Map<String, dynamic> _postLocationToJson(GeoJsonLocation location) =>
    location.toJson();

/// `posts` テーブル行の JSON 入出力用 DTO。
@JsonSerializable(explicitToJson: true)
final class PostDto {
  const PostDto({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.location,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;

  /// `posts.user_id`
  @JsonKey(name: 'user_id')
  final String userId;

  final String content;

  /// `posts.image_url`
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// ぼかし後の位置（GeoJSON Point）
  @JsonKey(fromJson: _postLocationFromJson, toJson: _postLocationToJson)
  final GeoJsonLocation location;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// ぼかし後の緯度（`ST_Y(location::geometry)` と同値想定）
  double get locationLat => location.latitude;

  /// ぼかし後の経度（`ST_X(location::geometry)` と同値想定）
  double get locationLng => location.longitude;

  factory PostDto.fromJson(Map<String, dynamic> json) => _$PostDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostDtoToJson(this);
}
