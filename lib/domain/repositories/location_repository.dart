import '../value_objects/geo_coordinate.dart';
import '../value_objects/location_permission_state.dart';

/// 端末の位置情報（生座標）。ぼかしは別の Domain サービス。
abstract interface class LocationRepository {
  Future<LocationPermissionState> requestPermission();

  Future<GeoCoordinate> getCurrentPosition();
}
