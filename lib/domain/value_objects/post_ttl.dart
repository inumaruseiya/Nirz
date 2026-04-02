/// 投稿の表示期限（作成からの TTL）。サーバでも `expires_at = now() + 24 hours` を強制する想定。
abstract final class PostTtl {
  PostTtl._();

  static const Duration value = Duration(hours: 24);
}
