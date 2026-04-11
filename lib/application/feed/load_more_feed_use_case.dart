import '../../domain/core/failure.dart';
import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../location/get_current_position_use_case.dart';
import '../../domain/core/location_position_exception.dart';

/// カーソル付きで次ページを取得（[LoadLocalFeedUseCase] と同様に閲覧者位置を毎回取得）。
final class LoadMoreFeedUseCase {
  LoadMoreFeedUseCase(this._feed, this._location);

  final FeedRepository _feed;
  final LocationRepository _location;

  Future<Result<List<FeedPost>, Failure>> call({
    required FeedCursor cursor,
    required FeedSort sort,
  }) async {
    try {
      final point = await _location.getCurrentPosition();
      return _feed.fetchFeed(
        viewerQueryPoint: point,
        cursor: cursor,
        sort: sort,
      );
    } on LocationPositionException catch (e) {
      return Err(GetCurrentPositionUseCase.mapFailure(e.issue));
    }
  }

  /// 既に取得済みの閲覧者地点でページングのみ行う場合。
  Future<Result<List<FeedPost>, Failure>> callWithViewerPoint({
    required GeoCoordinate viewerQueryPoint,
    required FeedCursor cursor,
    required FeedSort sort,
  }) {
    return _feed.fetchFeed(
      viewerQueryPoint: viewerQueryPoint,
      cursor: cursor,
      sort: sort,
    );
  }
}
