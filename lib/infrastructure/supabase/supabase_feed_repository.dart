import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../dto/rpc_feed_item_dto.dart';
import '../dto/rpc_feed_params.dart';
import '../mappers/post_mapper.dart';

/// [FeedRepository] の Supabase 実装（`get_local_feed` RPC）。
final class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<FeedPost>, Failure>> fetchFeed({
    required GeoCoordinate viewerQueryPoint,
    FeedCursor? cursor,
    required FeedSort sort,
  }) async {
    if (_client.auth.currentUser == null) {
      return const Err(AuthFailure());
    }
    final params = RpcFeedParams.forLocalFeed(
      viewerQueryPoint: viewerQueryPoint,
      cursor: cursor,
      sort: sort,
    );
    final clampedLimit = params.limit.clamp(1, 100);
    final rpcParams = RpcFeedParams(
      lat: params.lat,
      lng: params.lng,
      limit: clampedLimit,
      cursorCreatedAt: params.cursorCreatedAt,
      cursorId: params.cursorId,
      sort: params.sort,
    );
    try {
      final raw = await _client.rpc<dynamic>(
        'get_local_feed',
        params: rpcParams.toRpcMap(),
      );
      if (raw == null) {
        return const Ok([]);
      }
      if (raw is! List) {
        return const Err(ServerFailure());
      }
      final out = <FeedPost>[];
      for (final element in raw) {
        if (element is! Map) {
          return const Err(ServerFailure());
        }
        final row = Map<String, dynamic>.from(element);
        try {
          final dto = RpcFeedItemDto.fromJson(row);
          out.add(PostMapper.feedItemToDomain(dto));
        } on FormatException catch (e) {
          return Err(ValidationFailure(e.message));
        }
      }
      return Ok(out);
    } on AuthException {
      return const Err(AuthFailure());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrest(e));
    } on SocketException {
      return const Err(NetworkFailure());
    } catch (_) {
      return const Err(ServerFailure());
    }
  }

  static Failure _mapPostgrest(PostgrestException e) {
    final code = e.code;
    if (code == '22023' || code == 'P0001') {
      final msg = e.message.trim();
      return ValidationFailure(msg.isEmpty ? 'Invalid request' : msg);
    }
    if (code == '28000' || code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
