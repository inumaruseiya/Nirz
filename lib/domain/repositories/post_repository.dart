import '../core/failure.dart';
import '../core/result.dart';
import '../entities/post.dart';
import '../value_objects/obfuscated_location.dart';
import '../value_objects/post_id.dart';

/// 投稿の作成・削除。`expires_at` はサーバ（RPC）で固定する想定。
abstract interface class PostRepository {
  Future<Result<Post, Failure>> createPost({
    required String content,
    Uri? imageUrl,
    required ObfuscatedLocation location,
  });

  Future<Result<void, Failure>> deletePost(PostId id);
}
