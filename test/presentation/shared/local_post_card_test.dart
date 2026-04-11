import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:nirz/domain/entities/feed_post.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/presentation/shared/local_post_card.dart';

void main() {
  group('LocalPostCard', () {
    FeedPost buildPost({
      String content = '本文です',
      String? authorName,
      double? distanceKm,
      int reactionCount = 0,
      Uri? imageUrl,
      DateTime? createdAt,
    }) {
      final now = DateTime.now();
      final at = createdAt ?? now.subtract(const Duration(minutes: 5));
      return FeedPost(
        post: Post(
          id: PostId.parse('11111111-1111-1111-1111-111111111111'),
          authorId: UserId.parse('22222222-2222-2222-2222-222222222222'),
          content: content,
          imageUrl: imageUrl,
          location: ObfuscatedLocation(
            GeoCoordinate(latitude: 35.0, longitude: 139.0),
          ),
          createdAt: at,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
        reactionCount: reactionCount,
        authorName: authorName,
        distanceKm: distanceKm,
      );
    }

    testWidgets('表示: 著者名・本文・相対時刻・距離・リアクション数', (tester) async {
      final post = buildPost(
        authorName: 'テストユーザー',
        content: 'こんにちは',
        distanceKm: 1.2,
        reactionCount: 7,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LocalPostCard(post: post)),
        ),
      );

      expect(find.text('テストユーザー'), findsOneWidget);
      expect(find.text('こんにちは'), findsOneWidget);
      expect(find.text('2時間前'), findsOneWidget);
      expect(find.text('約 1.2 km'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('著者名が空のときは「近くのユーザー」', (tester) async {
      final post = buildPost(authorName: '   ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LocalPostCard(post: post)),
        ),
      );

      expect(find.text('近くのユーザー'), findsOneWidget);
    });

    testWidgets('距離が null のときは距離ラベルを出さない', (tester) async {
      final post = buildPost(distanceKm: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LocalPostCard(post: post)),
        ),
      );

      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('onTap ありでタップするとコールバックが呼ばれる', (tester) async {
      var tapped = false;
      final post = buildPost();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocalPostCard(post: post, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(LocalPostCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('imageUrl ありでサムネ領域が構築される', (tester) async {
      final post = buildPost(
        imageUrl: Uri.parse('https://example.com/image.png'),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: LocalPostCard(post: post)),
          ),
        );
        await tester.pump();
      });

      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });
}
