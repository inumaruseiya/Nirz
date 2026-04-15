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
import 'package:nirz/presentation/shared/local_post_card.dart';

/// Phase 12-6-4: フィード一覧は縦 [PageView.builder] による遅延構築（NFR-PERF-01）。
class _StaticFeedNotifier extends FeedNotifier {
  _StaticFeedNotifier(this._posts);

  final List<FeedPost> _posts;

  @override
  FeedState build() =>
      FeedReady(posts: _posts, sort: FeedSort.newest, hasMore: false);

  @override
  Future<void> loadInitial() async {}

  @override
  Future<bool> refresh() async => true;

  @override
  Future<bool> loadMore() async => true;
}

FeedPost _postAt(int i) {
  final now = DateTime.now();
  final idHex = i.toRadixString(16).padLeft(12, '0');
  return FeedPost(
    post: Post(
      id: PostId.parse('aaaaaaaa-aaaa-aaaa-aaaa-$idHex'),
      authorId: UserId.parse('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
      content: 'lazy_build_marker_$i',
      imageUrl: null,
      location: ObfuscatedLocation(
        GeoCoordinate(latitude: 35.0, longitude: 139.0),
      ),
      createdAt: now.subtract(Duration(minutes: i)),
      expiresAt: now.add(const Duration(hours: 24)),
    ),
    reactionCount: i % 3,
    authorName: 'ユーザー$i',
    distanceKm: 1.0 + i * 0.01,
  );
}

void main() {
  testWidgets('FeedReady: 狭い高さでは LocalPostCard が全件ビルドされない', (tester) async {
    const totalPosts = 24;
    final posts = List.generate(totalPosts, _postAt);

    await tester.binding.setSurfaceSize(const Size(400, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          feedNotifierProvider.overrideWith(() => _StaticFeedNotifier(posts)),
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
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.text('近くの投稿').evaluate().isNotEmpty) break;
    }
    await tester.pump();

    final built = tester.widgetList(find.byType(LocalPostCard)).length;
    expect(
      built,
      lessThan(totalPosts),
      reason: 'PageView.builder は表示域＋キャッシュのみ構築する想定（$built / $totalPosts）',
    );
    expect(built, greaterThan(0));
  });
}
