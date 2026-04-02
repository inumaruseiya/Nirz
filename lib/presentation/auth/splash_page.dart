import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../router/app_route_paths.dart';
import '../theme/app_tokens.dart';

/// スプラッシュ: ブランドマークと読み込みインジケータ（実装計画 Phase 5-1-1、詳細設計 4.1）。
///
/// セッション確認後の遷移は Phase 5-1-2 以降で [WatchSessionUseCase] 等に寄せる想定。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      context.go(AppRoutePaths.login);
      return;
    }
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    context.go(hasSession ? AppRoutePaths.feed : AppRoutePaths.login);
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
