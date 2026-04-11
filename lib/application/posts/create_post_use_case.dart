import 'dart:typed_data';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/ng_word_list_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/services/ng_word_moderation.dart';
import '../../domain/value_objects/obfuscated_location.dart';

/// ① NG ワード検査 ② 画像があれば Storage アップロード ③ ぼかし位置 ④ [PostRepository.createPost]。
final class CreatePostUseCase {
  CreatePostUseCase(this._posts, this._storage, this._ngWords);

  final PostRepository _posts;
  final StorageRepository _storage;
  final NgWordListRepository _ngWords;

  Future<Result<Post, Failure>> call({
    required String content,
    Uint8List? imageBytes,
    String? imageContentType,
    required ObfuscatedLocation obfuscatedLocation,
  }) async {
    final wordsResult = await _ngWords.loadNgWords();
    switch (wordsResult) {
      case Ok(:final value):
        final ngFail = ngWordValidationFailure(content, value);
        if (ngFail != null) {
          return Err(ngFail);
        }
      case Err(:final error):
        return Err(error);
    }

    Uri? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final ct = imageContentType?.trim();
      if (ct == null || ct.isEmpty) {
        return const Err(
          ValidationFailure(
            'imageContentType is required when imageBytes is set',
          ),
        );
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
