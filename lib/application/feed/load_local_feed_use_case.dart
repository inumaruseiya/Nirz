import '../../domain/core/failure.dart';
import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/core/location_position_exception.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../location/get_current_position_use_case.dart';

/// ① 現在位置（クエリ用の生座標）② [FeedRepository.fetchFeed]。
final class LoadLocalFeedUseCase {
  LoadLocalFeedUseCase(this._feed, this._location);

  final FeedRepository _feed;
  final LocationRepository _location;

  Future<Result<List<FeedPost>, Failure>> call({
    FeedCursor? cursor,
    required FeedSort sort,
  }) async {
    final posResult = await _getViewerPoint();
    switch (posResult) {
      case Ok(:final value):
        return _feed.fetchFeed(
          viewerQueryPoint: value,
          cursor: cursor,
          sort: sort,
        );
      case Err(:final error):
        return Err(error);
    }
  }

  Future<Result<GeoCoordinate, Failure>> _getViewerPoint() async {
    try {
      final coord = await _location.getCurrentPosition();
      return Ok(coord);
    } on LocationPositionException catch (e) {
      return Err(GetCurrentPositionUseCase.mapFailure(e.issue));
    }
  }
}
