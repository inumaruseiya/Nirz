import 'dart:typed_data';

import '../core/failure.dart';
import '../core/result.dart';

/// 投稿画像などバイナリのオブジェクトストレージへのアップロード。
abstract interface class StorageRepository {
  Future<Result<Uri, Failure>> uploadPostImage(
    Uint8List bytes,
    String contentType,
  );
}
