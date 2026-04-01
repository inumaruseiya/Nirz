import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../router/app_route_paths.dart';

/// セッション確認後にログインまたはフィードへ遷移（詳細は Phase 5）。
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
