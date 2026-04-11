import 'package:equatable/equatable.dart';

/// WGS84 の緯度・経度（度）。サーバに送るのはぼかし後のみ、というルールはユースケースで担保する。
final class GeoCoordinate extends Equatable {
  const GeoCoordinate._({required this.latitude, required this.longitude});

  /// [latitude] は [-90, 90]、[longitude] は [-180, 180]（端点含む）。
  factory GeoCoordinate({required double latitude, required double longitude}) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('latitude and longitude must be finite numbers');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'must be in [-90, 90]');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be in [-180, 180]',
      );
    }
    return GeoCoordinate._(latitude: latitude, longitude: longitude);
  }

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'GeoCoordinate($latitude, $longitude)';
}
