import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/services/location_obfuscation_service.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';

/// 2 点間の大圏距離（メートル）。WGS84 球近似 R = 6371000。
double greatCircleDistanceMeters(
  GeoCoordinate a,
  GeoCoordinate b,
) {
  const earthRadiusMeters = 6371000.0;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);
  final h = sinDLat * sinDLat +
      math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusMeters * c;
}

/// [from] から [to] への方位角（度、0〜360、北基準）。
double initialBearingDegrees(GeoCoordinate from, GeoCoordinate to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  var brng = math.atan2(y, x) * 180 / math.pi;
  return (brng + 360) % 360;
}

void main() {
  const minM = 300.0;
  const maxM = 1000.0;
  const epsM = 1.0; // 浮動小数の余裕

  group('LocationObfuscationService', () {
    test('offset distance is within 300m–1km (seeded samples)', () {
      final raw = GeoCoordinate(latitude: 35.6812, longitude: 139.7671);
      for (var seed = 0; seed < 80; seed++) {
        final svc = LocationObfuscationService(random: math.Random(seed));
        final blurred = svc.obfuscate(raw);
        final d = greatCircleDistanceMeters(raw, blurred.coordinate);
        expect(
          d,
          greaterThanOrEqualTo(minM - epsM),
          reason: 'seed=$seed distance=$d',
        );
        expect(
          d,
          lessThanOrEqualTo(maxM + epsM),
          reason: 'seed=$seed distance=$d',
        );
      }
    });

    test('obfuscated point is a valid GeoCoordinate (in bounds)', () {
      final raw = GeoCoordinate(latitude: -33.8688, longitude: 151.2093);
      final svc = LocationObfuscationService(random: math.Random(42));
      final blurred = svc.obfuscate(raw);
      expect(blurred.coordinate.latitude, inInclusiveRange(-90.0, 90.0));
      expect(blurred.coordinate.longitude, inInclusiveRange(-180.0, 180.0));
    });

    test('statistical sample: distance ~ uniform on [300, 1000]', () {
      final raw = GeoCoordinate(latitude: 48.8566, longitude: 2.3522);
      final random = math.Random(20260408);
      final svc = LocationObfuscationService(random: random);
      const n = 2400;
      const bins = 7;
      final counts = List<int>.filled(bins, 0);
      for (var i = 0; i < n; i++) {
        final d = greatCircleDistanceMeters(raw, svc.obfuscate(raw).coordinate);
        expect(d, inInclusiveRange(minM - epsM, maxM + epsM));
        final slot = ((d - minM) / (maxM - minM) * bins).floor();
        final idx = slot.clamp(0, bins - 1);
        counts[idx]++;
      }
      final expected = n / bins;
      var chi2 = 0.0;
      for (final c in counts) {
        final diff = c - expected;
        chi2 += diff * diff / expected;
      }
      // 一様分布の適合度（自由度 bins - 1）。p≈0.001 の閾値を緩めに採用してフレーク抑制。
      expect(chi2, lessThan(40.0), reason: 'distance bin counts=$counts chi2=$chi2');
    });

    test('statistical sample: bearing ~ uniform (no single quadrant dominates)', () {
      final raw = GeoCoordinate(latitude: 35.0, longitude: 139.0);
      final random = math.Random(7);
      final svc = LocationObfuscationService(random: random);
      const n = 2000;
      final quadrantCounts = [0, 0, 0, 0];
      for (var i = 0; i < n; i++) {
        final to = svc.obfuscate(raw).coordinate;
        final deg = initialBearingDegrees(raw, to);
        quadrantCounts[(deg / 90).floor().clamp(0, 3)]++;
      }
      final expected = n / 4;
      // 各象限が期待から大きく外れないこと（明らかな偏りの検知）
      for (var q = 0; q < 4; q++) {
        expect(
          quadrantCounts[q],
          inInclusiveRange((expected * 0.65).round(), (expected * 1.35).round()),
          reason: 'quadrant $q counts=$quadrantCounts',
        );
      }
    });
  });
}
