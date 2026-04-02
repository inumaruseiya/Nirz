/// `posts` テーブル行の JSON 入出力用 DTO。
///
/// PostgREST / Supabase の `geography(Point)` は通常 GeoJSON オブジェクトとして返る。
/// `coordinates` は **\[経度, 緯度\]**（RFC 7946）順。
final class PostDto {
  const PostDto({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.locationLat,
    required this.locationLng,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;

  /// `posts.user_id`
  final String userId;

  final String content;

  /// `posts.image_url`
  final String? imageUrl;

  /// ぼかし後の緯度（`ST_Y(location::geometry)` と同値想定）
  final double locationLat;

  /// ぼかし後の経度（`ST_X(location::geometry)` と同値想定）
  final double locationLng;

  final DateTime createdAt;
  final DateTime expiresAt;

  factory PostDto.fromJson(Map<String, dynamic> json) {
    final (lat, lng) = _parsePoint(json['location']);
    return PostDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: lat,
      locationLng: lng,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'location': {
          'type': 'Point',
          'coordinates': [locationLng, locationLat],
        },
        'created_at': createdAt.toUtc().toIso8601String(),
        'expires_at': expiresAt.toUtc().toIso8601String(),
      };

  /// GeoJSON `Point` または `coordinates` のみのマップを解釈する。
  static (double lat, double lng) _parsePoint(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw FormatException('location must be a GeoJSON object', raw);
    }
    final coords = raw['coordinates'];
    if (coords is! List || coords.length < 2) {
      throw FormatException('location.coordinates must be [lng, lat]', raw);
    }
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    return (lat, lng);
  }
}
