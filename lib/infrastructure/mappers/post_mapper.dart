import '../../domain/entities/feed_post.dart';
import '../../domain/entities/post.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../../domain/value_objects/obfuscated_location.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../dto/post_dto.dart';
import '../dto/rpc_feed_item_dto.dart';
import '../dto/rpc_post_detail_dto.dart';

/// [PostDto] / [RpcFeedItemDto] → ドメイン [Post] / [FeedPost]
final class PostMapper {
  const PostMapper._();

  static Post postToDomain(PostDto dto) {
    return Post(
      id: PostId.parse(dto.id),
      authorId: UserId.parse(dto.userId),
      content: dto.content,
      imageUrl: _optionalHttpUri(dto.imageUrl),
      location: ObfuscatedLocation(
        GeoCoordinate(latitude: dto.locationLat, longitude: dto.locationLng),
      ),
      createdAt: dto.createdAt,
      expiresAt: dto.expiresAt,
    );
  }

  static FeedPost postDetailToDomain(RpcPostDetailDto dto) {
    final post = Post(
      id: PostId.parse(dto.id),
      authorId: UserId.parse(dto.userId),
      content: dto.content,
      imageUrl: _optionalHttpUri(dto.imageUrl),
      location: ObfuscatedLocation(
        GeoCoordinate(latitude: dto.locationLat, longitude: dto.locationLng),
      ),
      createdAt: dto.createdAt,
      expiresAt: dto.expiresAt,
    );
    final author = dto.authorName.trim();
    return FeedPost(
      post: post,
      reactionCount: dto.reactionCount,
      authorName: author.isEmpty ? null : author,
      distanceKm: dto.distanceMeters / 1000.0,
      commentCount: dto.commentCount,
    );
  }

  static FeedPost feedItemToDomain(RpcFeedItemDto dto) {
    final post = Post(
      id: PostId.parse(dto.id),
      authorId: UserId.parse(dto.userId),
      content: dto.content,
      imageUrl: _optionalHttpUri(dto.imageUrl),
      location: ObfuscatedLocation(
        GeoCoordinate(latitude: dto.locationLat, longitude: dto.locationLng),
      ),
      createdAt: dto.createdAt,
      expiresAt: dto.expiresAt,
    );
    final author = dto.authorName.trim();
    return FeedPost(
      post: post,
      reactionCount: dto.reactionCount,
      authorName: author.isEmpty ? null : author,
      distanceKm: dto.distanceMeters / 1000.0,
    );
  }

  static Uri? _optionalHttpUri(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final u = Uri.tryParse(t);
    if (u == null || !u.hasScheme) return null;
    return u;
  }
}
