/// `get_post_detail` RPC の戻り（1行）の JSON 表現。
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
  final String userId;
  final String content;
  final String? imageUrl;
  final double locationLat;
  final double locationLng;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int reactionCount;
  final int commentCount;
  final String authorName;
  final double distanceMeters;

  factory RpcPostDetailDto.fromJson(Map<String, dynamic> json) {
    return RpcPostDetailDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      reactionCount: (json['reaction_count'] as num).toInt(),
      commentCount: (json['comment_count'] as num).toInt(),
      authorName: (json['author_name'] as String?) ?? '',
      distanceMeters: (json['distance_meters'] as num).toDouble(),
    );
  }
}
