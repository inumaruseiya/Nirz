import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../config/supabase_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';

/// スプラッシュ: ブランドマークと読み込みインジケータ（実装計画 Phase 5-1-1、詳細設計 4.1）。
///
/// セッション有無は [WatchSessionUseCase]（= [AuthRepository.watchSession]）の初回イベントで判定（Phase 5-1-2）。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  Future<void> _goNext() async {
    if (!mounted) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      context.go(AppRoutePaths.login);
      return;
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
          child: Semantics(
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
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusCard * 2),
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
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
