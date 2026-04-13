/// Supabase Auth のモバイル向けコールバック URL（OAuth / PKCE 等）。
///
/// Dashboard の **Authentication → URL Configuration → Redirect URLs** に
/// 次と同一の文字列を追加すること（末尾の `/` を含めて一致させる）。
abstract final class AuthDeepLinkConfig {
  /// カスタム URL スキーム（端末上で一意な逆ドメイン形式を推奨）。
  static const String scheme = 'io.nirz.app';

  /// ホスト名（任意。Dashboard 登録値と [oauthRedirectUrl] で揃える）。
  static const String host = 'auth-callback';

  /// [SupabaseClient.auth.signInWithOAuth] の `redirectTo` 等に渡す完全な URI。
  static const String oauthRedirectUrl = '$scheme://$host/';
}
