import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/infrastructure/dto/post_dto.dart';
import 'package:nirz/infrastructure/dto/rpc_feed_item_dto.dart';
import 'package:nirz/infrastructure/dto/rpc_post_detail_dto.dart';
import 'package:nirz/infrastructure/mappers/post_mapper.dart';

void main() {
  final created = DateTime.utc(2026, 4, 1);
  final expires = DateTime.utc(2026, 4, 2);

  group('PostMapper', () {
    test('postToDomain builds Post from PostDto', () {
      final dto = PostDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'body',
        imageUrl: 'https://cdn.example/i.png',
        location: const GeoJsonLocation(latitude: 35.0, longitude: 139.0),
        createdAt: created,
        expiresAt: expires,
      );
      final post = PostMapper.postToDomain(dto);
      expect(post.id, PostId.parse(dto.id));
      expect(post.authorId, UserId.parse(dto.userId));
      expect(post.content, 'body');
      expect(post.imageUrl, Uri.parse('https://cdn.example/i.png'));
      expect(post.location.coordinate.latitude, 35.0);
      expect(post.location.coordinate.longitude, 139.0);
      expect(post.createdAt, created);
      expect(post.expiresAt, expires);
    });

    test('feedItemToDomain converts distance m to km and trims author', () {
      final dto = RpcFeedItemDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'c',
        imageUrl: null,
        locationLat: 1,
        locationLng: 2,
        createdAt: created,
        expiresAt: expires,
        reactionCount: 5,
        authorName: '  Sam  ',
        distanceMeters: 2500,
      );
      final fp = PostMapper.feedItemToDomain(dto);
      expect(fp.reactionCount, 5);
      expect(fp.authorName, 'Sam');
      expect(fp.distanceKm, 2.5);
      expect(fp.commentCount, isNull);
    });

    test('postDetailToDomain sets commentCount', () {
      final dto = RpcPostDetailDto(
        id: '11111111-1111-4111-8111-111111111111',
        userId: '22222222-2222-4222-8222-222222222222',
        content: 'c',
        imageUrl: null,
        locationLat: 0,
        locationLng: 0,
        createdAt: created,
        expiresAt: expires,
        reactionCount: 0,
        commentCount: 9,
        authorName: '',
        distanceMeters: 0,
      );
      final fp = PostMapper.postDetailToDomain(dto);
      expect(fp.commentCount, 9);
    });
  });
}
