import 'package:equatable/equatable.dart';

/// フィードの keyset ページング用カーソル（直前ページ末尾の `created_at` + `id`）。
///
/// RPC の `cursor_created_at` / `cursor_id` に対応。`id` は投稿の UUID 文字列
///（後続タスクで `PostId` 値オブジェクトを導入したらその表現と揃える）。
final class FeedCursor extends Equatable {
  const FeedCursor({
    required this.createdAt,
    required this.id,
  });

  final DateTime createdAt;

  /// 投稿 ID（非空 UUID 文字列を前提とする）。
  final String id;

  @override
  List<Object?> get props => [createdAt, id];
}
