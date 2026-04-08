import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';

void main() {
  group('GeoCoordinate', () {
    test('accepts boundary latitudes and longitudes', () {
      final minCorner = GeoCoordinate(latitude: -90, longitude: -180);
      expect(minCorner.latitude, -90);
      expect(minCorner.longitude, -180);
      final maxCorner = GeoCoordinate(latitude: 90, longitude: 180);
      expect(maxCorner.latitude, 90);
      expect(maxCorner.longitude, 180);
    });

    test('accepts interior values', () {
      final c = GeoCoordinate(latitude: 35.6812, longitude: 139.7671);
      expect(c.latitude, 35.6812);
      expect(c.longitude, 139.7671);
    });

    test('rejects latitude below -90', () {
      expect(
        () => GeoCoordinate(latitude: -90.0001, longitude: 0),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'latitude')),
      );
    });

    test('rejects latitude above 90', () {
      expect(
        () => GeoCoordinate(latitude: 90.0001, longitude: 0),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'latitude')),
      );
    });

    test('rejects longitude below -180', () {
      expect(
        () => GeoCoordinate(latitude: 0, longitude: -180.0001),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'longitude')),
      );
    });

    test('rejects longitude above 180', () {
      expect(
        () => GeoCoordinate(latitude: 0, longitude: 180.0001),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'longitude')),
      );
    });

    test('rejects non-finite latitude', () {
      expect(
        () => GeoCoordinate(latitude: double.nan, longitude: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => GeoCoordinate(latitude: double.infinity, longitude: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-finite longitude', () {
      expect(
        () => GeoCoordinate(latitude: 0, longitude: double.nan),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality uses latitude and longitude', () {
      final a = GeoCoordinate(latitude: 1, longitude: 2);
      final b = GeoCoordinate(latitude: 1, longitude: 2);
      final c = GeoCoordinate(latitude: 1, longitude: 3);
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });
}
