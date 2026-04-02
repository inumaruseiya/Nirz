/// ローカルフィードの並び順（`get_local_feed` の `sort` に対応）。
enum FeedSort {
  /// 新着順（`created_at` 降順など）。
  newest,

  /// 人気順（リアクション数など）。
  popular,
}
