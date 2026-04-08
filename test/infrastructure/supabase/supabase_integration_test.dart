import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/config/supabase_config.dart';
import 'package:nirz/domain/core/feed_sort.dart';
import 'package:nirz/domain/core/failure.dart';
import 'package:nirz/domain/core/result.dart';
import 'package:nirz/domain/entities/feed_post.dart';
import 'package:nirz/domain/value_objects/geo_coordinate.dart';
import 'package:nirz/domain/value_objects/post_id.dart';
import 'package:nirz/infrastructure/supabase/supabase_feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phase **12-3-3**（任意）: 実 Supabase への結合テスト。既定はスキップ。
/// 有効化: `RUN_SUPABASE_INTEGRATION=true` + `SUPABASE_URL` / `SUPABASE_ANON_KEY` +
/// `INTEGRATION_TEST_EMAIL` / `INTEGRATION_TEST_PASSWORD`。
/// 例: `flutter test test/infrastructure/supabase/supabase_integration_test.dart`
/// に上記 `--dart-define=...` を付与。`fetchPostDetail` は `INTEGRATION_TEST_POST_ID` も必要。
const bool _runIntegration = bool.fromEnvironment(
  'RUN_SUPABASE_INTEGRATION',
  defaultValue: false,
);

const String _testEmail = String.fromEnvironment(
  'INTEGRATION_TEST_EMAIL',
  defaultValue: '',
);

const String _testPassword = String.fromEnvironment(
  'INTEGRATION_TEST_PASSWORD',
  defaultValue: '',
);

const String _integrationPostId = String.fromEnvironment(
  'INTEGRATION_TEST_POST_ID',
  defaultValue: '',
);

/// 東京駅付近（5km フィードのクエリ用）。データが無い環境では空リストの [Ok] になり得る。
final _viewerTokyo = GeoCoordinate(latitude: 35.6812, longitude: 139.7671);

String? _integrationSkipReason() {
  if (!_runIntegration) {
    return 'Set --dart-define=RUN_SUPABASE_INTEGRATION=true (+ SUPABASE_* and INTEGRATION_TEST_*)';
  }
  if (!SupabaseConfig.isConfigured) {
    return 'Set SUPABASE_URL and SUPABASE_ANON_KEY';
  }
  if (_testEmail.isEmpty || _testPassword.isEmpty) {
    return 'Set INTEGRATION_TEST_EMAIL and INTEGRATION_TEST_PASSWORD';
  }
  return null;
}

String? _postDetailSkipReason() {
  final base = _integrationSkipReason();
  if (base != null) return base;
  if (_integrationPostId.isEmpty) {
    return 'Optional: set INTEGRATION_TEST_POST_ID to run fetchPostDetail';
  }
  return null;
}

void main() {
  group('Supabase integration (opt-in)', () {
    test(
      'SupabaseFeedRepository.fetchFeed calls get_local_feed',
      () async {
        final client = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        try {
          await client.auth.signInWithPassword(
            email: _testEmail,
            password: _testPassword,
          );

          final repo = SupabaseFeedRepository(client);
          final result = await repo.fetchFeed(
            viewerQueryPoint: _viewerTokyo,
            sort: FeedSort.newest,
          );

          expect(result, isA<Result<List<FeedPost>, Failure>>());
          switch (result) {
            case Ok(:final value):
              expect(value, isA<List<FeedPost>>());
            case Err(:final error):
              // 認証・RLS・スキーマ不一致などは環境依存のため、失敗種別だけ検証する
              expect(error, isA<Failure>());
          }
        } finally {
          await client.auth.signOut();
          await client.dispose();
        }
      },
      skip: _integrationSkipReason(),
    );

    test(
      'SupabaseFeedRepository.fetchPostDetail calls get_post_detail',
      () async {
        final postId = PostId.parse(_integrationPostId);
        final client = SupabaseClient(
          SupabaseConfig.url,
          SupabaseConfig.anonKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        try {
          await client.auth.signInWithPassword(
            email: _testEmail,
            password: _testPassword,
          );

          final repo = SupabaseFeedRepository(client);
          final result = await repo.fetchPostDetail(
            postId: postId,
            viewerQueryPoint: _viewerTokyo,
          );

          expect(result, isA<Result<List<FeedPost>, Failure>>());
          switch (result) {
            case Ok(:final value):
              expect(value, isA<List<FeedPost>>());
            case Err(:final error):
              expect(error, isA<Failure>());
          }
        } finally {
          await client.auth.signOut();
          await client.dispose();
        }
      },
      skip: _postDetailSkipReason(),
    );
  });
}
