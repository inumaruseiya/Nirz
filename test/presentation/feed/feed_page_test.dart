import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirz/domain/core/feed_sort.dart';
import 'package:nirz/domain/entities/feed_post.dart';
import 'package:nirz/domain/entities/post.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/obfuscated_location.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/domain/value_objects/user_id.dart';
import 'package:nirz/presentation/feed/feed_notifier.dart';
import 'package:nirz/presentation/feed/feed_page.dart';
import 'package:nirz/presentation/router/app_route_paths.dart';
import 'package:nirz/presentation/shared/feed_skeleton_card.dart';

/// [loadInitial] を実行しても状態が変わらない（Widget テスト用）。
final class _StaticFeedNotifier extends FeedNotifier {
  _StaticFeedNotifier(this._fixed);

  final FeedState _fixed;

  @override
  FeedState build() => _fixed;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<bool> refresh() async => true;

  @override
  Future<bool> loadMore() async => true;
}

FeedPost _samplePost({String content = 'フィード本文'}) {
  final now = DateTime.now();
  return FeedPost(
    post: Post(
      id: PostId.parse('33333333-3333-3333-3333-333333333333'),
      authorId: UserId.parse('44444444-4444-4444-4444-444444444444'),
      content: content,
      imageUrl: null,
      location: ObfuscatedLocation(
        GeoCoordinate(latitude: 35.0, longitude: 139.0),
      ),
      createdAt: now.subtract(const Duration(minutes: 3)),
      expiresAt: now.add(const Duration(hours: 24)),
    ),
    reactionCount: 2,
    authorName: '投稿者A',
    distanceKm: 0.5,
  );
}

Future<void> _pumpFeedPage(
  WidgetTester tester, {
  required FeedState feedState,
}) async {
  // SliverList は遅延構築のため、十分な高さを確保して複数スケルトンをビルドさせる。
  await tester.binding.setSurfaceSize(const Size(400, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedNotifierProvider.overrideWith(() => _StaticFeedNotifier(feedState)),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutePaths.feed,
          routes: [
            GoRoute(
              path: AppRoutePaths.feed,
              builder: (context, state) => const FeedPage(),
            ),
            GoRoute(
              path: AppRoutePaths.compose,
              builder: (context, state) =>
                  const Scaffold(body: Text('compose_stub')),
            ),
            GoRoute(
              path: AppRoutePaths.settings,
              builder: (context, state) =>
                  const Scaffold(body: Text('settings_stub')),
            ),
            GoRoute(
              path: '${AppRoutePaths.postDetailPrefix}:postId',
              builder: (context, state) =>
                  const Scaffold(body: Text('detail_stub')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('FeedPage', () {
    testWidgets('FeedLoading: スケルトンと読み込みセマンティクス', (tester) async {
      await _pumpFeedPage(tester, feedState: const FeedLoading());

      expect(find.text('近くの投稿'), findsOneWidget);
      expect(find.byType(FeedSkeletonCard), findsNWidgets(3));
      expect(find.bySemanticsLabel('近くの投稿を読み込んでいます'), findsOneWidget);
    });

    testWidgets('FeedReady: 投稿カードが表示される', (tester) async {
      await _pumpFeedPage(
        tester,
        feedState: FeedReady(
          posts: [_samplePost(content: 'ユニーク本文XYZ')],
          sort: FeedSort.newest,
          hasMore: false,
        ),
      );

      expect(find.text('ユニーク本文XYZ'), findsOneWidget);
      expect(find.byType(FeedSkeletonCard), findsNothing);
    });

    testWidgets('FeedEmpty: 空メッセージとCTA', (tester) async {
      await _pumpFeedPage(tester, feedState: const FeedEmpty());

      expect(find.text('まだ近くに投稿がありません'), findsOneWidget);
      expect(find.text('最初の投稿をする'), findsOneWidget);
    });

    testWidgets('FeedError: エラーパネルと再試行', (tester) async {
      await _pumpFeedPage(tester, feedState: const FeedError('テスト用エラー'));

      expect(find.text('読み込めませんでした'), findsOneWidget);
      expect(find.text('テスト用エラー'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('FeedLocationDenied: 位置権限コールアウト', (tester) async {
      await _pumpFeedPage(tester, feedState: const FeedLocationDenied());

      expect(find.text('位置情報をオンにしてください'), findsOneWidget);
      expect(find.text('設定を開く'), findsOneWidget);
    });
  });
}
