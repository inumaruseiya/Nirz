import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

/// 認証状態が変わったときに発火するストリーム（リダイレクト再評価用）。
Stream<void> authStateRefreshStream() {
  if (!SupabaseConfig.isConfigured) {
    return const Stream<void>.empty();
  }
  return Supabase.instance.client.auth.onAuthStateChange.map((_) {});
}

bool get isAuthSessionActive {
  if (!SupabaseConfig.isConfigured) {
    return false;
  }
  return Supabase.instance.client.auth.currentSession != null;
}
