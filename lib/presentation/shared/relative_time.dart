/// 投稿カード等向けの相対時刻（日本語・ざっくり）（実装計画 Phase 6-2-3、詳細設計 4.3）。
///
/// [clock] を省略すると [DateTime.now] を使う（テストでは固定時刻を渡せる）。
String formatRelativeTimeJa(DateTime createdAt, {DateTime? clock}) {
  final now = clock ?? DateTime.now();
  final at = createdAt.isUtc ? createdAt.toLocal() : createdAt;
  final diff = now.difference(at);
  if (diff.isNegative) return 'たった今';
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}週間前';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}ヶ月前';
  return '${(diff.inDays / 365).floor()}年前';
}
