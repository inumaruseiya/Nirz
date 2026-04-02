import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/login_page.dart';
import '../auth/splash_page.dart';
import '../compose/compose_page.dart';
import '../detail/post_detail_page.dart';
import '../feed/feed_page.dart';
import '../settings/settings_page.dart';
import 'app_route_paths.dart';
import 'auth_refresh_stream.dart';
import 'go_router_refresh_stream.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(authStateRefreshStream());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    refreshListenable: refresh,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.feed,
        builder: (context, state) => const FeedPage(),
      ),
      GoRoute(
        path: AppRoutePaths.compose,
        pageBuilder: (context, state) => const MaterialPage<void>(
          key: ValueKey<String>(AppRoutePaths.compose),
          fullscreenDialog: true,
          child: ComposePage(),
        ),
      ),
      GoRoute(
        path: '${AppRoutePaths.postDetailPrefix}:postId',
        builder: (context, state) {
          final id = state.pathParameters['postId']!;
          return PostDetailPage(postId: id);
        },
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

String? _redirect(BuildContext context, GoRouterState state) {
  final loggedIn = isAuthSessionActive;
  final loc = state.matchedLocation;
  final onSplash = loc == AppRoutePaths.splash;
  final onLogin = loc == AppRoutePaths.login;

  // スプラッシュでのセッション判定・遷移は [SplashPage] が [WatchSessionUseCase] で行う（Phase 5-1-2）。
  if (loggedIn && onLogin) {
    return AppRoutePaths.feed;
  }
  if (!loggedIn && !onSplash && !onLogin) {
    return AppRoutePaths.login;
  }
  return null;
}
