import '../../domain/core/failure.dart';
import '../../domain/core/location_position_exception.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/geo_coordinate.dart';

final class GetCurrentPositionUseCase {
  GetCurrentPositionUseCase(this._location);

  final LocationRepository _location;

  Future<Result<GeoCoordinate, Failure>> call() async {
    try {
      final coord = await _location.getCurrentPosition();
      return Ok(coord);
    } on LocationPositionException catch (e) {
      return Err(mapFailure(e.issue));
    }
  }

  /// [LocationRepository.getCurrentPosition] の失敗をドメイン [Failure] に変換する。
  static Failure mapFailure(LocationPositionIssue issue) {
    switch (issue) {
      case LocationPositionIssue.permissionDenied:
      case LocationPositionIssue.permissionDeniedForever:
      case LocationPositionIssue.locationServicesDisabled:
      case LocationPositionIssue.unknown:
        return const LocationFailure();
      case LocationPositionIssue.timeout:
        return const NetworkFailure();
    }
  }
}
