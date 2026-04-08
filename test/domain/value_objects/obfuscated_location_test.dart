import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';

void main() {
  group('ObfuscatedLocation', () {
    test('holds wrapped coordinate', () {
      final coord = GeoCoordinate(latitude: 35.0, longitude: 139.0);
      final obfuscated = ObfuscatedLocation(coord);
      expect(obfuscated.coordinate, coord);
      expect(obfuscated.coordinate.latitude, 35.0);
      expect(obfuscated.coordinate.longitude, 139.0);
    });

    test('equality is based on coordinate', () {
      final c1 = GeoCoordinate(latitude: 1, longitude: 2);
      final c2 = GeoCoordinate(latitude: 1, longitude: 2);
      expect(ObfuscatedLocation(c1), ObfuscatedLocation(c2));
      expect(
        ObfuscatedLocation(c1),
        isNot(ObfuscatedLocation(GeoCoordinate(latitude: 1, longitude: 3))),
      );
    });

    test('toString includes coordinate', () {
      final coord = GeoCoordinate(latitude: 0, longitude: 0);
      expect(
        ObfuscatedLocation(coord).toString(),
        'ObfuscatedLocation(GeoCoordinate(0.0, 0.0))',
      );
    });
  });
}
