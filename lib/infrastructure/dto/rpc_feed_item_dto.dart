/// `get_local_feed` RPC の1行分の JSON 表現。
///
/// サーバの `RETURNS TABLE`（snake_case）とキーを揃える。
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
  final String userId;
  final String content;
  final String? imageUrl;
  final double locationLat;
  final double locationLng;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// `reaction_count`（bigint → JSON では number）
  final int reactionCount;

  /// `author_name`（`profiles.name`、未設定時は空文字になり得る）
  final String authorName;

  /// `distance_meters`（閲覧者クエリ地点からの距離・メートル）
  final double distanceMeters;

  factory RpcFeedItemDto.fromJson(Map<String, dynamic> json) {
    return RpcFeedItemDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      reactionCount: (json['reaction_count'] as num).toInt(),
      authorName: (json['author_name'] as String?) ?? '',
      distanceMeters: (json['distance_meters'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'created_at': createdAt.toUtc().toIso8601String(),
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'reaction_count': reactionCount,
        'author_name': authorName,
        'distance_meters': distanceMeters,
      };
}
