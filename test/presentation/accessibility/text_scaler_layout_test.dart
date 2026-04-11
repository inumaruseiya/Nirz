import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/entities/feed_post.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/presentation/shared/error_retry_panel.dart';
import 'package:nirz/presentation/shared/feed_skeleton_card.dart';
import 'package:nirz/presentation/shared/local_post_card.dart';
import 'package:nirz/presentation/shared/location_permission_callout.dart';
import 'package:nirz/presentation/shared/reaction_picker.dart';
import 'package:nirz/presentation/theme/app_theme.dart';
import 'package:nirz/presentation/theme/app_tokens.dart';

/// Phase 12-5-2: 大きな [TextScaler] でもレイアウト例外が出ないこと（詳細設計 10）。
void main() {
  group('TextScaler layout', () {
    FeedPost samplePost() {
      final now = DateTime.now();
      return FeedPost(
        post: Post(
          id: PostId.parse('11111111-1111-1111-1111-111111111111'),
          authorId: UserId.parse('22222222-2222-2222-2222-222222222222'),
          content:
              '本文が長い場合の折り返しと、大きな文字サイズの組み合わせを確認します。'
              '近くの出来事や気持ちを書いてください。',
          imageUrl: null,
          location: ObfuscatedLocation(
            GeoCoordinate(latitude: 35.0, longitude: 139.0),
          ),
          createdAt: now.subtract(const Duration(hours: 1)),
          expiresAt: now.add(const Duration(hours: 24)),
        ),
        reactionCount: 12,
        authorName: 'ニックネームがやや長めのユーザー',
        distanceKm: 2.3,
      );
    }

    Future<void> pumpScaled(
      WidgetTester tester, {
      required double scale,
      required Widget child,
    }) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              size: const Size(360, 640),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: child,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('scale 2.0: 主要ウィジェットを縦スクロールで組み合わせ', (tester) async {
      await pumpScaled(
        tester,
        scale: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocalPostCard(post: samplePost()),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            const FeedSkeletonCard(),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            ReactionPicker(selected: ReactionType.like, onChanged: (_) {}),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            LocationPermissionCallout(onOpenSettings: () {}),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            ErrorRetryPanel(
              message: '接続できませんでした。通信環境を確認してください。',
              onRetry: () {},
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('scale 3.0: 同様に例外なし', (tester) async {
      await pumpScaled(
        tester,
        scale: 3.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocalPostCard(post: samplePost()),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            ReactionPicker(selected: null, onChanged: (_) {}),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
