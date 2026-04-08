import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/core/feed_cursor.dart';
import 'package:nirz/domain/core/feed_sort.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/infrastructure/dto/rpc_feed_params.dart';

void main() {
  final viewer = GeoCoordinate(latitude: 35.1, longitude: 139.2);
  final cursor = FeedCursor(
    createdAt: DateTime.utc(2026, 3, 15, 8, 30),
    id: '11111111-1111-4111-8111-111111111111',
  );

  group('RpcFeedParams', () {
    test('forLocalFeed maps sort and viewer coordinates', () {
      final p = RpcFeedParams.forLocalFeed(
        viewerQueryPoint: viewer,
        sort: FeedSort.popular,
        limit: 50,
      );
      expect(p.lat, 35.1);
      expect(p.lng, 139.2);
      expect(p.limit, 50);
      expect(p.sort, 'popular');
      expect(p.cursorCreatedAt, isNull);
      expect(p.cursorId, isNull);
    });

    test('forLocalFeed passes cursor fields', () {
      final p = RpcFeedParams.forLocalFeed(
        viewerQueryPoint: viewer,
        cursor: cursor,
        sort: FeedSort.newest,
      );
      expect(p.cursorCreatedAt, cursor.createdAt);
      expect(p.cursorId, cursor.id);
      expect(p.sort, 'newest');
    });

    test('toRpcMap uses p_* keys and ISO8601 cursor', () {
      final p = RpcFeedParams.forLocalFeed(
        viewerQueryPoint: viewer,
        cursor: cursor,
        sort: FeedSort.newest,
        limit: 20,
      );
      final map = p.toRpcMap();
      expect(map['p_lat'], 35.1);
      expect(map['p_lng'], 139.2);
      expect(map['p_limit'], 20);
      expect(map['p_sort'], 'newest');
      expect(map['p_cursor_id'], cursor.id);
      expect(
        map['p_cursor_created_at'],
        cursor.createdAt.toUtc().toIso8601String(),
      );
    });

    test('toRpcMap nulls cursor when absent', () {
      final p = RpcFeedParams.forLocalFeed(
        viewerQueryPoint: viewer,
        sort: FeedSort.newest,
      );
      final map = p.toRpcMap();
      expect(map['p_cursor_created_at'], isNull);
      expect(map['p_cursor_id'], isNull);
    });
  });
}
