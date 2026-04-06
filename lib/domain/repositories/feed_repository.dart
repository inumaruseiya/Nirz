import '../core/failure.dart';
import '../core/feed_cursor.dart';
import '../core/feed_sort.dart';
import '../core/result.dart';
import '../entities/feed_post.dart';
import '../value_objects/geo_coordinate.dart';
import '../value_objects/post_id.dart';

/// ローカルフィード取得（閲覧者のクエリ用座標は永続化しない）。
abstract interface class FeedRepository {
  Future<Result<List<FeedPost>, Failure>> fetchFeed({
    required GeoCoordinate viewerQueryPoint,
    FeedCursor? cursor,
    required FeedSort sort,
  });

  /// 単一投稿（`get_local_feed` と同様の 5km・未失効の範囲内のみ）。該当なしは空リスト。
  Future<Result<List<FeedPost>, Failure>> fetchPostDetail({
    required PostId postId,
    required GeoCoordinate viewerQueryPoint,
  });
}
