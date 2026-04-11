import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/storage_repository.dart';

/// [StorageRepository] の Supabase Storage 実装（`post-images` バケット）。
///
/// アップロードパスはマイグレーション方針どおり `{auth.uid()}/{objectName}`。
final class SupabaseStorageRepository implements StorageRepository {
  SupabaseStorageRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'post-images';
  static const _maxBytes = 5242880; // 5 MiB（Phase 1-5 マイグレーションと一致）
  static const _uuid = Uuid();

  @override
  Future<Result<Uri, Failure>> uploadPostImage(
    Uint8List bytes,
    String contentType,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return const Err(AuthFailure());
    }

    final ct = contentType.trim();
    if (ct.isEmpty) {
      return const Err(ValidationFailure('contentType must be non-empty'));
    }
    if (bytes.isEmpty) {
      return const Err(ValidationFailure('image bytes must be non-empty'));
    }
    if (bytes.length > _maxBytes) {
      return const Err(ValidationFailure('image exceeds maximum size (5 MiB)'));
    }

    final ext = _extensionForContentType(ct);
    final objectName = '${_uuid.v4()}$ext';
    final path = '$uid/$objectName';

    try {
      final bucket = _client.storage.from(_bucket);
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: ct, upsert: true),
      );
      final publicUrl = bucket.getPublicUrl(path);
      final uri = Uri.tryParse(publicUrl);
      if (uri == null || !uri.hasScheme) {
        return const Err(ServerFailure());
      }
      return Ok(uri);
    } on StorageException catch (e) {
      return Err(_mapStorage(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  static String _extensionForContentType(String contentType) {
    final base = contentType.toLowerCase().split(';').first.trim();
    if (base == 'image/jpeg' || base == 'image/jpg') {
      return '.jpg';
    }
    if (base == 'image/png') {
      return '.png';
    }
    if (base == 'image/webp') {
      return '.webp';
    }
    if (base == 'image/gif') {
      return '.gif';
    }
    return '';
  }

  static Failure _mapStorage(StorageException e) {
    final code = e.statusCode;
    if (code == '401' || code == '403') {
      return const AuthFailure();
    }
    if (code == '413') {
      return const ValidationFailure('image exceeds maximum size (5 MiB)');
    }
    final msg = e.message.trim();
    if (msg.toLowerCase().contains('payload too large') ||
        msg.toLowerCase().contains('file size')) {
      return ValidationFailure(msg.isEmpty ? 'File too large' : msg);
    }
    return const ServerFailure();
  }
}
