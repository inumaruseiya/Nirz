import '../../domain/core/failure.dart';
import '../../domain/core/location_position_exception.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../../domain/value_objects/post_id.dart';
import '../location/get_current_position_use_case.dart';

/// 閲覧者の現在位置で `get_post_detail` を呼び、該当投稿を 1 件返す（範囲外・失効は空）。
final class LoadPostDetailUseCase {
  LoadPostDetailUseCase(
    this._feed,
    this._location,
  );

  final FeedRepository _feed;
  final LocationRepository _location;

  Future<Result<List<FeedPost>, Failure>> call(PostId postId) async {
    final posResult = await _getViewerPoint();
    switch (posResult) {
      case Ok(:final value):
        return _feed.fetchPostDetail(
          postId: postId,
          viewerQueryPoint: value,
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
