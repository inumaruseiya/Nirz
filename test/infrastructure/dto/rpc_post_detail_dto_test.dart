import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/infrastructure/dto/rpc_post_detail_dto.dart';

void main() {
  final created = DateTime.utc(2026, 4, 1);
  final expires = DateTime.utc(2026, 4, 2);

  group('RpcPostDetailDto', () {
    test('fromJson parses comment_count and author_name fallback', () {
      final dto = RpcPostDetailDto.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'user_id': '22222222-2222-4222-8222-222222222222',
        'content': 'c',
        'image_url': null,
        'location_lat': 1.0,
        'location_lng': 2.0,
        'created_at': created.toIso8601String(),
        'expires_at': expires.toIso8601String(),
        'reaction_count': 3,
        'comment_count': 7,
        'author_name': null,
        'distance_meters': 500.0,
      });
      expect(dto.commentCount, 7);
      expect(dto.authorName, '');
    });

    test('toJson round-trip', () {
      final original = RpcPostDetailDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'x',
        imageUrl: null,
        locationLat: 10,
        locationLng: 20,
        createdAt: created,
        expiresAt: expires,
        reactionCount: 0,
        commentCount: 0,
        authorName: 'N',
        distanceMeters: 0,
      );
      final back = RpcPostDetailDto.fromJson(original.toJson());
      expect(back.commentCount, original.commentCount);
      expect(back.reactionCount, original.reactionCount);
    });
  });
}
