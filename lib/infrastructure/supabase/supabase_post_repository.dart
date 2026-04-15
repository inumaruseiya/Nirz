import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/value_objects/obfuscated_location.dart';
import '../../domain/value_objects/post_id.dart';
import '../dto/post_dto.dart';
import '../mappers/post_mapper.dart';
import 'postgrest_failure_mapper.dart';

/// [PostRepository] の Supabase 実装（`create_post` RPC・`posts` DELETE）。
final class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<Post, Failure>> createPost({
    required String content,
    Uri? imageUrl,
    required ObfuscatedLocation location,
  }) async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure());
    }
    try {
      final raw = await _client.rpc<dynamic>(
        'create_post',
        params: <String, dynamic>{
          'p_content': content,
          'p_image_url': imageUrl?.toString(),
          'p_lat_blurred': location.coordinate.latitude,
          'p_lng_blurred': location.coordinate.longitude,
        },
      );
      final row = _singleRowFromRpc(raw);
      if (row == null) {
        return const Err(ServerFailure());
      }
      final dto = PostDto.fromJson(row);
      return Ok(PostMapper.postToDomain(dto));
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } on FormatException catch (e) {
      return Err(ValidationFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<void, Failure>> deletePost(PostId id) async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure());
    }
    try {
      await _client.from('posts').delete().eq('id', id.value);
      return const Ok<void, Failure>(null);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(mapPostgrestException(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  /// `SETOF posts` の RPC はリスト、単一行の場合はマップになることがある。
  static Map<String, dynamic>? _singleRowFromRpc(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is List) {
      if (raw.isEmpty) {
        return null;
      }
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
      return null;
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
