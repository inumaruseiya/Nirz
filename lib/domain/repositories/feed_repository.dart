import '../core/failure.dart';
import '../core/feed_cursor.dart';
import '../core/feed_sort.dart';
import '../core/result.dart';
import '../entities/feed_post.dart';
import '../value_objects/geo_coordinate.dart';

/// ローカルフィード取得（閲覧者のクエリ用座標は永続化しない）。
abstract interface class FeedRepository {
  Future<Result<List<FeedPost>, Failure>> fetchFeed({
    required GeoCoordinate viewerQueryPoint,
    FeedCursor? cursor,
    required FeedSort sort,
  });
}
