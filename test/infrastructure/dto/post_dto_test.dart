import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/post_dto.dart';

void main() {
  final created = DateTime.utc(2026, 4, 1);
  final expires = DateTime.utc(2026, 4, 2);

  group('GeoJsonLocation', () {
    test('fromJson swaps coordinates to lat/lng', () {
      final loc = GeoJsonLocation.fromJson({
        'type': 'Point',
        'coordinates': [139.7, 35.6],
      });
      expect(loc.longitude, 139.7);
      expect(loc.latitude, 35.6);
    });

    test('toJson round-trip', () {
      const loc = GeoJsonLocation(latitude: 1.5, longitude: 2.5);
      final back = GeoJsonLocation.fromJson(loc.toJson());
      expect(back.latitude, loc.latitude);
      expect(back.longitude, loc.longitude);
    });

    test('rejects non-Point type', () {
      expect(
        () => GeoJsonLocation.fromJson({
          'type': 'LineString',
          'coordinates': [0, 0],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects short coordinates', () {
      expect(
        () => GeoJsonLocation.fromJson({
          'type': 'Point',
          'coordinates': [139.0],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PostDto', () {
    test(
      'fromJson accepts location as WKT POINT (PostgREST geography string)',
      () {
        final dto = PostDto.fromJson({
          'id': '11111111-1111-4111-8111-111111111111',
          'user_id': '22222222-2222-4222-8222-222222222222',
          'content': 'hello',
          'image_url': null,
          'location': 'SRID=4326;POINT(139.0 35.5)',
          'created_at': created.toIso8601String(),
          'expires_at': expires.toIso8601String(),
        });
        expect(dto.locationLat, 35.5);
        expect(dto.locationLng, 139.0);
      },
    );

    test('fromJson accepts location as JSON string of GeoJSON', () {
      final dto = PostDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'hello',
        'image_url': null,
        'location': '{"type":"Point","coordinates":[139.25,35.75]}',
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
      expect(dto.locationLat, 35.75);
      expect(dto.locationLng, 139.25);
    });

    test('fromJson accepts location as [lng, lat] list (PostgREST)', () {
      final dto = PostDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'hello',
        'image_url': null,
        'location': [139.0, 35.5],
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
      expect(dto.locationLat, 35.5);
      expect(dto.locationLng, 139.0);
    });

    test('fromJson accepts location as PostGIS EWKB hex (no SRID)', () {
      final dto = PostDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'hello',
        'image_url': null,
        'location':
            '010100000000000000006061400000000000c04140', // POINT(139 35.5) LE
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
      expect(dto.locationLat, closeTo(35.5, 1e-9));
      expect(dto.locationLng, closeTo(139.0, 1e-9));
    });

    test('fromJson accepts location as PostGIS EWKB hex (SRID 4326)', () {
      final dto = PostDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'hello',
        'image_url': null,
        'location':
            '0101000020e610000000000000006061400000000000c04140',
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
      expect(dto.locationLat, closeTo(35.5, 1e-9));
      expect(dto.locationLng, closeTo(139.0, 1e-9));
    });

    test('fromJson accepts WKT POINT with comma between coordinates', () {
      final dto = PostDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'hello',
        'image_url': null,
        'location': 'POINT(139.0, 35.5)',
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
      });
      expect(dto.locationLat, 35.5);
      expect(dto.locationLng, 139.0);
    });

    test('fromJson / toJson round-trip', () {
      final original = PostDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'hello',
        imageUrl: 'https://x.test/img.png',
        location: const GeoJsonLocation(latitude: 35.0, longitude: 139.0),
        createdAt: created,
        expiresAt: expires,
      );
      final back = PostDto.fromJson(original.toJson());
      expect(back.id, original.id);
      expect(back.userId, original.userId);
      expect(back.content, original.content);
      expect(back.imageUrl, original.imageUrl);
      expect(back.locationLat, 35.0);
      expect(back.locationLng, 139.0);
      expect(back.createdAt, original.createdAt);
      expect(back.expiresAt, original.expiresAt);
    });
  });
}
