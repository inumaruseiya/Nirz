import 'dart:convert';
import 'dart:typed_data';

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

/// PostgREST は `geography` を **ネストした GeoJSON**、**WKT**、**EWKB 16 進**、
/// **`[lng,lat]` の JSON 配列** などで返すことがある（RPC `create_post` の戻りなど）。
GeoJsonLocation _postLocationFromJson(Object? json) {
  if (json == null) {
    throw FormatException('location is null', json);
  }
  if (json is Map) {
    return GeoJsonLocation.fromJson(Map<String, dynamic>.from(json));
  }
  if (json is List) {
    if (json.length >= 2 && json[0] is num && json[1] is num) {
      return GeoJsonLocation(
        longitude: (json[0] as num).toDouble(),
        latitude: (json[1] as num).toDouble(),
      );
    }
    throw FormatException('location list must be [lng, lat] numbers', json);
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
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List &&
            decoded.length >= 2 &&
            decoded[0] is num &&
            decoded[1] is num) {
          return GeoJsonLocation(
            longitude: (decoded[0] as num).toDouble(),
            latitude: (decoded[1] as num).toDouble(),
          );
        }
      } on FormatException {
        throw FormatException('location coordinates JSON string is invalid', json);
      }
    }
    final ewkb = _tryParsePostgisEwkbHexPoint(trimmed);
    if (ewkb != null) {
      return ewkb;
    }
    final wktPart = trimmed.contains(';')
        ? trimmed.split(';').last.trim()
        : trimmed;
    final pointMatch = RegExp(
      r'^POINT\s*\(\s*([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*,?\s*'
      r'([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\s*\)$',
      caseSensitive: false,
    ).firstMatch(wktPart);
    if (pointMatch != null) {
      final lng = double.parse(pointMatch.group(1)!);
      final lat = double.parse(pointMatch.group(2)!);
      return GeoJsonLocation(latitude: lat, longitude: lng);
    }
    throw FormatException(
      'location must be GeoJSON object, JSON string, WKT POINT, EWKB hex, or [lng,lat]',
      json,
    );
  }
  throw FormatException('location must be a GeoJSON object', json);
}

/// PostGIS EWKB の **Point（2D）** を 16 進文字列から復元する（SRID 付き `0x20000001` または素の `1`）。
GeoJsonLocation? _tryParsePostgisEwkbHexPoint(String hex) {
  final s = hex.trim();
  if (s.isEmpty || s.length.isOdd) {
    return null;
  }
  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) {
    return null;
  }
  final byteLen = s.length ~/ 2;
  if (byteLen < 21) {
    return null;
  }
  final bytes = Uint8List(byteLen);
  for (var i = 0; i < s.length; i += 2) {
    bytes[i ~/ 2] = int.parse(s.substring(i, i + 2), radix: 16);
  }
  final bd = ByteData.sublistView(bytes);
  if (bytes[0] != 1) {
    return null;
  }
  final wkbType = bd.getUint32(1, Endian.little);
  var coordOffset = 5;
  const pointWithSrid = 0x20000001;
  if (wkbType == pointWithSrid) {
    coordOffset += 4;
  } else if (wkbType != 1) {
    return null;
  }
  if (bytes.length < coordOffset + 16) {
    return null;
  }
  final lng = bd.getFloat64(coordOffset, Endian.little);
  final lat = bd.getFloat64(coordOffset + 8, Endian.little);
  if (!lat.isFinite || !lng.isFinite) {
    return null;
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return null;
  }
  return GeoJsonLocation(latitude: lat, longitude: lng);
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
