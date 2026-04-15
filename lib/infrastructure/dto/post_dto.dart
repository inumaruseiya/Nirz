import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'post_dto.g.dart';

/// PostgREST / Supabase の `geography(Point)` が GeoJSON として返るときの入れ子表現。
///
/// `coordinates` は **\[経度, 緯度\]**（RFC 7946）順。
final class GeoJsonLocation {
  const GeoJsonLocation({required this.latitude, required this.longitude});

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

/// PostgREST は `geography` を **ネストした GeoJSON** ではなく **WKT 文字列** や
/// **JSON 文字列化した GeoJSON** で返すことがある（本番 RPC `create_post` の戻りなど）。
GeoJsonLocation _postLocationFromJson(Object? json) {
  if (json is Map) {
    return GeoJsonLocation.fromJson(Map<String, dynamic>.from(json));
  }
  if (json is String) {
    final trimmed = json.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return GeoJsonLocation.fromJson(Map<String, dynamic>.from(decoded));
        }
      } on FormatException {
        throw FormatException('location JSON string is invalid', json);
      }
    }
    final wktPart = trimmed.contains(';')
        ? trimmed.split(';').last.trim()
        : trimmed;
    final pointMatch = RegExp(
      r'^POINT\s*\(\s*([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s+'
      r'([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*\)$',
      caseSensitive: false,
    ).firstMatch(wktPart);
    if (pointMatch != null) {
      final lng = double.parse(pointMatch.group(1)!);
      final lat = double.parse(pointMatch.group(2)!);
      return GeoJsonLocation(latitude: lat, longitude: lng);
    }
    throw FormatException(
      'location must be GeoJSON object, JSON string, or WKT POINT',
      json,
    );
  }
  throw FormatException('location must be a GeoJSON object', json);
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

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostDtoToJson(this);
}
