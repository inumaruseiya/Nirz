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
import 'package:nirz/presentation/shared/relative_time.dart';
import 'package:nirz/presentation/theme/app_theme.dart';

/// Phase 12-5-5: フィード 1 件の読み上げ順（詳細設計 10・実装計画 12-5-5）。
///
/// VoiceOver / TalkBack の手動確認の補助として、[LocalPostCard] の統合
/// [Semantics.label] の語順を固定する。
void main() {
  group('Screen reader order (feed card)', () {
    FeedPost buildPost({
      required String authorName,
      required String content,
      required DateTime createdAt,
      double? distanceKm,
      int reactionCount = 3,
      Uri? imageUrl,
    }) {
      final expires = createdAt.add(const Duration(hours: 24));
      return FeedPost(
        post: Post(
          id: PostId.parse('cccccccc-cccc-cccc-cccc-cccccccccccc'),
          authorId: UserId.parse('dddddddd-dddd-dddd-dddd-dddddddddddd'),
          content: content,
          imageUrl: imageUrl,
          location: ObfuscatedLocation(
            GeoCoordinate(latitude: 35.0, longitude: 139.0),
          ),
          createdAt: createdAt,
          expiresAt: expires,
        ),
        reactionCount: reactionCount,
        authorName: authorName,
        distanceKm: distanceKm,
      );
    }

    testWidgets('統合ラベルは「著者→相対時刻→距離→本文→(画像)→リアクション」の順', (tester) async {
      // [LocalPostCard] は clock なしで [formatRelativeTimeJa] を呼ぶため、期待値も同じ。
      final createdAt = DateTime.now().subtract(const Duration(minutes: 15));
      final relative = formatRelativeTimeJa(createdAt);

      const name = '山田太郎';
      const content = '今日はいい天気です。';
      const distance = '約 1.2 km';
      const reactionPhrase =
          'リアクション合計 2 件（いいね・見た・炎の合計）';

      final post = buildPost(
        authorName: name,
        content: content,
        createdAt: createdAt,
        distanceKm: 1.2,
        reactionCount: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: LocalPostCard(
              post: post,
              onTap: () {},
            ),
          ),
        ),
      );

      final label = tester
          .getSemantics(find.byType(LocalPostCard))
          .getSemanticsData()
          .label;

      expect(
        label,
        '$name、$relative、$distance。$content。$reactionPhrase',
      );

      expect(label.indexOf(name), lessThan(label.indexOf(relative)));
      expect(label.indexOf(relative), lessThan(label.indexOf(distance)));
      expect(label.indexOf(distance), lessThan(label.indexOf(content)));
      expect(label.indexOf(content), lessThan(label.indexOf(reactionPhrase)));
    });

    testWidgets('画像ありのとき本文の直後に「画像あり。」が入る', (tester) async {
      final createdAt = DateTime.now().subtract(const Duration(seconds: 20));
      final relative = formatRelativeTimeJa(createdAt);

      const name = '近くのユーザー';
      const content = '写真付き投稿';
      const reactionPhrase = 'リアクションなし';

      final post = buildPost(
        authorName: '  ',
        content: content,
        createdAt: createdAt,
        distanceKm: null,
        reactionCount: 0,
        imageUrl: Uri.parse('https://example.com/x.jpg'),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: LocalPostCard(post: post),
            ),
          ),
        );
        await tester.pump();
      });

      final label = tester
          .getSemantics(find.byType(LocalPostCard))
          .getSemanticsData()
          .label;

      expect(
        label,
        '$name、$relative。$content。画像あり。$reactionPhrase',
      );
      expect(label.indexOf(content), lessThan(label.indexOf('画像あり')));
      expect(label.indexOf('画像あり'), lessThan(label.indexOf(reactionPhrase)));
    });
  });
}
