import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';

void main() {
  group('Post.isExpired', () {
    final base = DateTime.utc(2026, 4, 1, 12, 0, 0);
    final location = ObfuscatedLocation(
      GeoCoordinate(latitude: 35.0, longitude: 139.0),
    );

    Post build({required DateTime expiresAt}) {
      return Post(
        id: PostId.parse('11111111-1111-4111-8111-111111111111'),
        authorId: UserId.parse('22222222-2222-4222-8222-222222222222'),
        content: 'hello',
        location: location,
        createdAt: base,
        expiresAt: expiresAt,
      );
    }

    test('is true when expiresAt is in the past', () {
      final post = build(expiresAt: base.subtract(const Duration(seconds: 1)));
      expect(post.isExpired, isTrue);
    });

    test('is false when expiresAt is in the future', () {
      final post = build(
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 365)),
      );
      expect(post.isExpired, isFalse);
    });

    test('is true when expiresAt equals now (inclusive expiry boundary)', () {
      final anchor = DateTime.now();
      final post = build(expiresAt: anchor);
      // Same instant: `expiresAt.isAfter(now)` is false → treated as expired.
      expect(post.isExpired, isTrue);
    });
  });

  group('Post', () {
    test('equality uses all fields', () {
      final loc = ObfuscatedLocation(
        GeoCoordinate(latitude: 0, longitude: 0),
      );
      final a = Post(
        id: PostId.parse('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
        authorId: UserId.parse('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
        content: 'x',
        imageUrl: Uri.parse('https://example.com/a.png'),
        location: loc,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );
      final b = Post(
        id: PostId.parse('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
        authorId: UserId.parse('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
        content: 'x',
        imageUrl: Uri.parse('https://example.com/a.png'),
        location: loc,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );
      final differentImage = Post(
        id: PostId.parse('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
        authorId: UserId.parse('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
        content: 'x',
        imageUrl: null,
        location: loc,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
      );
      expect(a, b);
      expect(a, isNot(differentImage));
    });
  });
}
