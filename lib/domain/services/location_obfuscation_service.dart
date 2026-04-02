import 'dart:math' as math;

import '../value_objects/geo_coordinate.dart';
import '../value_objects/obfuscated_location.dart';

/// 生 [GeoCoordinate] を **300m〜1km** のランダム直線距離でオフセットし [ObfuscatedLocation] にする（FR-LOC-03）。
///
/// 方位角は一様、距離は区間上で一様。小距離の目的地は球面三角法（bearing + angular distance）で算出する。
class LocationObfuscationService {
  LocationObfuscationService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  static const double _earthRadiusMeters = 6371000;
  static const double _minOffsetMeters = 300;
  static const double _maxOffsetMeters = 1000;

  ObfuscatedLocation obfuscate(GeoCoordinate raw) {
    final distanceMeters = _minOffsetMeters +
        _random.nextDouble() * (_maxOffsetMeters - _minOffsetMeters);
    final bearingRadians = 2 * math.pi * _random.nextDouble();

    final lat1 = raw.latitude * math.pi / 180;
    final lon1 = raw.longitude * math.pi / 180;
    final angularDistance = distanceMeters / _earthRadiusMeters;

    final sinLat1 = math.sin(lat1);
    final cosLat1 = math.cos(lat1);
    final sinDelta = math.sin(angularDistance);
    final cosDelta = math.cos(angularDistance);

    final lat2 = math.asin(
      sinLat1 * cosDelta + cosLat1 * sinDelta * math.cos(bearingRadians),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearingRadians) * sinDelta * cosLat1,
          cosDelta - sinLat1 * math.sin(lat2),
        );

    var latDeg = lat2 * 180 / math.pi;
    var lonDeg = lon2 * 180 / math.pi;
    lonDeg = _normalizeLongitudeDegrees(lonDeg);

    if (latDeg > 90) {
      latDeg = 90;
    } else if (latDeg < -90) {
      latDeg = -90;
    }

    final blurred = GeoCoordinate(latitude: latDeg, longitude: lonDeg);
    return ObfuscatedLocation(blurred);
  }

  static double _normalizeLongitudeDegrees(double deg) {
    var d = deg;
    while (d > 180) {
      d -= 360;
    }
    while (d < -180) {
      d += 360;
    }
    return d;
  }
}
