import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/rpc_feed_item_dto.dart';

void main() {
  final created = DateTime.utc(2026, 4, 1);
  final expires = DateTime.utc(2026, 4, 2);

  group('RpcFeedItemDto', () {
    test('fromJson parses bigint-like numbers and null author', () {
      final dto = RpcFeedItemDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'c',
        'image_url': null,
        'location_lat': 35.5,
        'location_lng': 139.5,
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
        'reaction_count': 42,
        'author_name': null,
        'distance_meters': 1500.25,
      });
      expect(dto.reactionCount, 42);
      expect(dto.authorName, '');
      expect(dto.distanceMeters, 1500.25);
    });

    test('toJson round-trip', () {
      final original = RpcFeedItemDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'x',
        imageUrl: 'https://a/b',
        locationLat: 0,
        locationLng: 0,
        createdAt: created,
        expiresAt: expires,
        reactionCount: 1,
        authorName: 'Z',
        distanceMeters: 100,
      );
      final back = RpcFeedItemDto.fromJson(original.toJson());
      expect(back.id, original.id);
      expect(back.userId, original.userId);
      expect(back.reactionCount, original.reactionCount);
      expect(back.authorName, original.authorName);
    });
  });
}
