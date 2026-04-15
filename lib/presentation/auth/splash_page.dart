import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../config/supabase_config.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/providers.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';

/// スプラッシュ: ブランドマークと読み込みインジケータ（実装計画 Phase 5-1-1、詳細設計 4.1）。
///
/// セッション確認は [AuthRepository.refreshAuthSession]（ネットワーク到達性）のあと
/// [WatchSessionUseCase] の初回イベントで判定（Phase 5-1-2 / 5-1-3）。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

enum _SplashUi { loading, errorOffline }

class _SplashPageState extends ConsumerState<SplashPage> {
  _SplashUi _ui = _SplashUi.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSessionFlow());
  }

  Future<void> _runSessionFlow() async {
    if (!mounted) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      context.go(AppRoutePaths.login);
      return;
    }
    setState(() => _ui = _SplashUi.loading);

    final auth = ref.read(authRepositoryProvider);
    final Result<void, Failure> refreshed = await auth.refreshAuthSession();
    if (!mounted) {
      return;
    }
    if (refreshed case Err(error: final Failure e)) {
      if (e is NetworkFailure) {
        setState(() => _ui = _SplashUi.errorOffline);
        return;
      }
    }

    final watchSession = ref.read(watchSessionUseCaseProvider);
    final SessionState state = await watchSession().first;
    if (!mounted) {
      return;
    }
    switch (state) {
      case SessionSignedIn():
        context.go(AppRoutePaths.feed);
      case SessionSignedOut():
        context.go(AppRoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: switch (_ui) {
            _SplashUi.loading => Semantics(
              label: 'Nirz、起動中',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'Nirz ロゴ',
                    excludeSemantics: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusCard * 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
                        child: Icon(
                          Icons.map_outlined,
                          size: 56,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTokens.spaceUnit * 3),
                  Text(
                    'Nirz',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppTokens.spaceUnit * 4),
                  Semantics(
                    label: '読み込み中',
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _SplashUi.errorOffline => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.screenHorizontalInset,
              ),
              child: Semantics(
                label: 'ネットワークに接続できません。接続を確認してから再試行してください。',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Nirz ロゴ',
                      excludeSemantics: true,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusCard * 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppTokens.spaceUnit * 2,
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 56,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppTokens.spaceUnit * 3),
                    Text(
                      'オフラインです',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTokens.spaceUnit * 2),
                    Text(
                      'インターネット接続を確認してから、もう一度お試しください。',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTokens.spaceUnit * 4),
                    FilledButton.icon(
                      onPressed: _runSessionFlow,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
