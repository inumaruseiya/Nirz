import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';

/// ローカルフィード画面の状態（実装計画 Phase 6-1-2、詳細設計 5.1）。
sealed class FeedState {
  const FeedState();
}

/// まだ初回取得を開始していない（画面マウント直後）。
final class FeedInitial extends FeedState {
  const FeedInitial();
}

/// 初回取得中、または pull-to-refresh 相当の全件差し替え中。
final class FeedLoading extends FeedState {
  const FeedLoading();
}

/// 1 件以上表示可能。
final class FeedReady extends FeedState {
  const FeedReady({
    required this.posts,
    required this.sort,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<FeedPost> posts;
  final FeedSort sort;

  /// 直近ページが [pageSize] 件なら続きがある可能性あり。
  final bool hasMore;
  final FeedCursor? nextCursor;

  /// 1 ページあたりの件数（`RpcFeedParams.defaultFeedRpcLimit` と一致させる）。
  static const int pageSize = 20;
}

/// 取得成功だが 0 件。
final class FeedEmpty extends FeedState {
  const FeedEmpty();
}

/// 位置が取得できずフィードを出せない（権限・サービス停止など）。
final class FeedLocationDenied extends FeedState {
  const FeedLocationDenied();
}

/// ネットワーク・サーバー・認証など。
final class FeedError extends FeedState {
  const FeedError(this.message);

  final String message;
}

final class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedInitial();

  /// フィードの先頭ページを取得し状態を更新する。
  Future<void> loadInitial() async {
    state = const FeedLoading();
    final useCase = ref.read(loadLocalFeedUseCaseProvider);
    final result = await useCase(cursor: null, sort: FeedSort.newest);
    state = _stateFromFirstPage(result);
  }

  /// [loadInitial] と同じ（Pull-to-refresh 用）。
  Future<void> refresh() => loadInitial();

  FeedState _stateFromFirstPage(Result<List<FeedPost>, Failure> result) {
    switch (result) {
      case Ok(:final value):
        if (value.isEmpty) {
          return const FeedEmpty();
        }
        final last = value.last;
        final hasMore = value.length >= FeedReady.pageSize;
        final next = hasMore
            ? FeedCursor(createdAt: last.createdAt, id: last.id.value)
            : null;
        return FeedReady(
          posts: value,
          sort: FeedSort.newest,
          hasMore: hasMore,
          nextCursor: next,
        );
      case Err(:final error):
        return switch (error) {
          LocationFailure() => const FeedLocationDenied(),
          _ => FeedError(_messageForFailure(error)),
        };
    }
  }

  String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => '接続できませんでした。通信環境を確認してください。',
      AuthFailure() => 'セッションの有効期限が切れました。再度ログインしてください。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報を利用できません。',
    };
  }
}

final feedNotifierProvider =
    NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
