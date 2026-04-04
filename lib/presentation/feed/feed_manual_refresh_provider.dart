import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 投稿作成から戻ったときにインクリメントする。Phase 6 のフィード再取得と接続する。
final feedManualRefreshTriggerProvider = StateProvider<int>((ref) => 0);
