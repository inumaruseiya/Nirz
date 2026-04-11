import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nirz/application/feed/load_local_feed_use_case.dart';
import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/domain/core/feed_cursor.dart';
import 'package:nirz/domain/core/feed_sort.dart';
import 'package:nirz/domain/core/location_position_exception.dart';
import 'package:nirz/domain/core/result.dart';
import 'package:nirz/domain/entities/feed_post.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/repositories/feed_repository.dart';
import 'package:nirz/domain/repositories/location_repository.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';

class _MockFeedRepository extends Mock implements FeedRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  final viewer = GeoCoordinate(latitude: 35.1, longitude: 139.2);
  final obfuscated = ObfuscatedLocation(
    GeoCoordinate(latitude: 35.0, longitude: 139.0),
  );
  final cursor = FeedCursor(
    createdAt: DateTime.utc(2026, 3, 1),
    id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  );

  FeedPost feedPost({String content = 'hi'}) {
    final post = Post(
      id: PostId.parse('11111111-1111-4111-8111-111111111111'),
      authorId: UserId.parse('22222222-2222-4222-8222-222222222222'),
      content: content,
      location: obfuscated,
      createdAt: DateTime.utc(2026, 4, 1),
      expiresAt: DateTime.utc(2026, 4, 2),
    );
    return FeedPost(post: post, reactionCount: 1, authorName: 'a');
  }

  late _MockFeedRepository feed;
  late _MockLocationRepository location;
  late LoadLocalFeedUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FeedSort.newest);
    registerFallbackValue(GeoCoordinate(latitude: 0, longitude: 0));
  });

  setUp(() {
    feed = _MockFeedRepository();
    location = _MockLocationRepository();
    useCase = LoadLocalFeedUseCase(feed, location);
  });

  group('LoadLocalFeedUseCase', () {
    test('fetches feed with viewer point when position succeeds', () async {
      when(() => location.getCurrentPosition()).thenAnswer((_) async => viewer);
      when(
        () => feed.fetchFeed(
          viewerQueryPoint: viewer,
          cursor: cursor,
          sort: FeedSort.popular,
        ),
      ).thenAnswer((_) async => Ok([feedPost()]));

      final result = await useCase(cursor: cursor, sort: FeedSort.popular);

      expect(result, isA<Ok<List<FeedPost>, Failure>>());
      expect((result as Ok).value, hasLength(1));
      expect((result as Ok).value.single.content, 'hi');
      verify(() => location.getCurrentPosition()).called(1);
      verify(
        () => feed.fetchFeed(
          viewerQueryPoint: viewer,
          cursor: cursor,
          sort: FeedSort.popular,
        ),
      ).called(1);
    });

    test('passes null cursor for first page', () async {
      when(() => location.getCurrentPosition()).thenAnswer((_) async => viewer);
      when(
        () => feed.fetchFeed(
          viewerQueryPoint: viewer,
          cursor: null,
          sort: FeedSort.newest,
        ),
      ).thenAnswer((_) async => const Ok([]));

      final result = await useCase(sort: FeedSort.newest);

      expect(result, const Ok<List<FeedPost>, Failure>([]));
      verify(
        () => feed.fetchFeed(
          viewerQueryPoint: viewer,
          cursor: null,
          sort: FeedSort.newest,
        ),
      ).called(1);
    });

    test('returns empty list when feed is empty', () async {
      when(() => location.getCurrentPosition()).thenAnswer((_) async => viewer);
      when(
        () => feed.fetchFeed(
          viewerQueryPoint: any(named: 'viewerQueryPoint'),
          cursor: any(named: 'cursor'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => const Ok([]));

      final result = await useCase(sort: FeedSort.newest);

      expect(result, const Ok<List<FeedPost>, Failure>([]));
    });

    test('propagates fetchFeed failure', () async {
      when(() => location.getCurrentPosition()).thenAnswer((_) async => viewer);
      when(
        () => feed.fetchFeed(
          viewerQueryPoint: viewer,
          cursor: null,
          sort: FeedSort.newest,
        ),
      ).thenAnswer((_) async => const Err(ServerFailure()));

      final result = await useCase(sort: FeedSort.newest);

      expect(result, isA<Err<List<FeedPost>, Failure>>());
      expect((result as Err).error, isA<ServerFailure>());
    });

    test('maps location permission denied to LocationFailure', () async {
      when(() => location.getCurrentPosition()).thenThrow(
        LocationPositionException(LocationPositionIssue.permissionDenied),
      );

      final result = await useCase(sort: FeedSort.newest);

      expect(result, isA<Err<List<FeedPost>, Failure>>());
      expect((result as Err).error, isA<LocationFailure>());
      verifyNever(
        () => feed.fetchFeed(
          viewerQueryPoint: any(named: 'viewerQueryPoint'),
          cursor: any(named: 'cursor'),
          sort: any(named: 'sort'),
        ),
      );
    });

    test('maps location timeout to NetworkFailure', () async {
      when(
        () => location.getCurrentPosition(),
      ).thenThrow(LocationPositionException(LocationPositionIssue.timeout));

      final result = await useCase(sort: FeedSort.newest);

      expect(result, isA<Err<List<FeedPost>, Failure>>());
      expect((result as Err).error, isA<NetworkFailure>());
      verifyNever(
        () => feed.fetchFeed(
          viewerQueryPoint: any(named: 'viewerQueryPoint'),
          cursor: any(named: 'cursor'),
          sort: any(named: 'sort'),
        ),
      );
    });
  });
}
