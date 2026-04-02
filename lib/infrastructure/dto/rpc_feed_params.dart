import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/value_objects/geo_coordinate.dart';

/// `get_local_feed` RPC 呼び出し用パラメータ（サーバの `p_*` 名と対応）。
///
/// [limit] はサーバ制約 **1〜100**（`FeedRepository` 実装側でクランプ推奨）。
final class RpcFeedParams {
  const RpcFeedParams({
    required this.lat,
    required this.lng,
    this.limit = defaultFeedRpcLimit,
    this.cursorCreatedAt,
    this.cursorId,
    required this.sort,
  });

  static const int defaultFeedRpcLimit = 20;

  final double lat;
  final double lng;
  final int limit;
  final DateTime? cursorCreatedAt;
  final String? cursorId;

  /// `p_sort` に渡す値（`newest` / `popular`）。
  final String sort;

  /// 閲覧者クエリ地点・ドメインの並び順・カーソルから組み立てる。
  factory RpcFeedParams.forLocalFeed({
    required GeoCoordinate viewerQueryPoint,
    FeedCursor? cursor,
    required FeedSort sort,
    int limit = defaultFeedRpcLimit,
  }) {
    return RpcFeedParams(
      lat: viewerQueryPoint.latitude,
      lng: viewerQueryPoint.longitude,
      limit: limit,
      cursorCreatedAt: cursor?.createdAt,
      cursorId: cursor?.id,
      sort: switch (sort) {
        FeedSort.newest => 'newest',
        FeedSort.popular => 'popular',
      },
    );
  }

  /// [SupabaseClient.rpc] に渡すマップ（PostgreSQL 引数名どおり `p_*`）。
  Map<String, dynamic> toRpcMap() {
    return {
      'p_lat': lat,
      'p_lng': lng,
      'p_limit': limit,
      'p_sort': sort,
      'p_cursor_created_at': cursorCreatedAt?.toUtc().toIso8601String(),
      'p_cursor_id': cursorId,
    };
  }
}
