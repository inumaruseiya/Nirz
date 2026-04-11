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
import 'package:nirz/presentation/theme/app_theme.dart';

/// Phase 12-5-3: 画像まわりの意味づけ（実装計画 12-5-3、詳細設計 10）。
void main() {
  group('Image semantics', () {
    FeedPost buildPost({Uri? imageUrl}) {
      final now = DateTime.now();
      return FeedPost(
        post: Post(
          id: PostId.parse('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
          authorId: UserId.parse('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
          content: '本文',
          imageUrl: imageUrl,
          location: ObfuscatedLocation(
            GeoCoordinate(latitude: 35.0, longitude: 139.0),
          ),
          createdAt: now.subtract(const Duration(minutes: 1)),
          expiresAt: now.add(const Duration(hours: 24)),
        ),
        reactionCount: 0,
        authorName: 'ユーザー',
        distanceKm: 1.0,
      );
    }

    testWidgets('LocalPostCard: 画像ありのとき統合ラベルに「画像あり」', (tester) async {
      final post = buildPost(imageUrl: Uri.parse('https://example.com/p.png'));

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(body: LocalPostCard(post: post)),
          ),
        );
        await tester.pump();
      });

      final semantics = tester
          .getSemantics(find.byType(LocalPostCard))
          .getSemanticsData();
      expect(semantics.label, contains('画像あり'));
    });

    testWidgets('LocalPostCard: 画像なしのとき「画像あり」を含まない', (tester) async {
      final post = buildPost(imageUrl: null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: LocalPostCard(post: post)),
        ),
      );

      final semantics = tester
          .getSemantics(find.byType(LocalPostCard))
          .getSemanticsData();
      expect(semantics.label, isNot(contains('画像あり')));
    });
  });
}
