import 'dart:typed_data';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/value_objects/obfuscated_location.dart';

/// ① 画像があれば Storage アップロード ② ぼかし位置 ③ [PostRepository.createPost]。
final class CreatePostUseCase {
  CreatePostUseCase(
    this._posts,
    this._storage,
  );

  final PostRepository _posts;
  final StorageRepository _storage;

  Future<Result<Post, Failure>> call({
    required String content,
    Uint8List? imageBytes,
    String? imageContentType,
    required ObfuscatedLocation obfuscatedLocation,
  }) async {
    Uri? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final ct = imageContentType?.trim();
      if (ct == null || ct.isEmpty) {
        return const Err(ValidationFailure('imageContentType is required when imageBytes is set'));
      }
      final upload = await _storage.uploadPostImage(imageBytes, ct);
      switch (upload) {
        case Ok(:final value):
          imageUrl = value;
        case Err(:final error):
          return Err(error);
      }
    }

    return _posts.createPost(
      content: content,
      imageUrl: imageUrl,
      location: obfuscatedLocation,
    );
  }
}
