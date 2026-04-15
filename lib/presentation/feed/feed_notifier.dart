import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/feed_cursor.dart';
import '../../domain/core/feed_sort.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/value_objects/location_permission_state.dart';

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
    this.loadingMore = false,
  });

  final List<FeedPost> posts;
  final FeedSort sort;

  /// 直近ページが [pageSize] 件なら続きがある可能性あり。
  final bool hasMore;
  final FeedCursor? nextCursor;

  /// 次ページ取得中（末尾インジケータ用）。
  final bool loadingMore;

  /// 1 ページあたりの件数（`RpcFeedParams.defaultFeedRpcLimit` と一致させる）。
  static const int pageSize = 20;
}

/// [FeedReady] と同じ一覧を保ちつつ先頭ページを再取得中（Pull-to-refresh）。
final class FeedRefreshing extends FeedState {
  const FeedRefreshing({
    required this.posts,
    required this.sort,
    this.hasMore = false,
    this.nextCursor,
  });

  final List<FeedPost> posts;
  final FeedSort sort;
  final bool hasMore;
  final FeedCursor? nextCursor;
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

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedInitial();

  /// フィードの先頭ページを取得し状態を更新する。
  Future<void> loadInitial() async {
    state = const FeedLoading();
    final permission = await ref
        .read(requestLocationPermissionUseCaseProvider)
        .call();
    if (permission != LocationPermissionState.granted) {
      state = const FeedLocationDenied();
      return;
    }
    final useCase = ref.read(loadLocalFeedUseCaseProvider);
    final result = await useCase(cursor: null, sort: FeedSort.newest);
    state = _stateFromFirstPage(result);
  }

  /// Pull-to-refresh。一覧表示中はリストを消さず再取得する。
  ///
  /// 戻り値: 再取得成功時 true。失敗時 false（一覧表示中の失敗は直前の [FeedReady] に戻す）。
  Future<bool> refresh() async {
    if (state is FeedRefreshing) {
      return true;
    }

    final current = state;
    if (current is FeedReady) {
      state = FeedRefreshing(
        posts: current.posts,
        sort: current.sort,
        hasMore: current.hasMore,
        nextCursor: current.nextCursor,
      );
    } else {
      await loadInitial();
      return state is! FeedError;
    }

    final useCase = ref.read(loadLocalFeedUseCaseProvider);
    final result = await useCase(cursor: null, sort: FeedSort.newest);

    switch (result) {
      case Ok():
        state = _stateFromFirstPage(result);
        return true;
      case Err():
        state = FeedReady(
          posts: current.posts,
          sort: current.sort,
          hasMore: current.hasMore,
          nextCursor: current.nextCursor,
          loadingMore: false,
        );
        return false;
    }
  }

  /// 末尾スクロールで呼び出す。`LoadMoreFeedUseCase` でカーソルページング。
  ///
  /// 続きなし・取得中・一覧以外のときは何もしない。戻り値は取得の成否（SnackBar 等に利用可）。
  Future<bool> loadMore() async {
    final s = state;
    if (s is! FeedReady ||
        s.loadingMore ||
        !s.hasMore ||
        s.nextCursor == null) {
      return true;
    }

    final cursor = s.nextCursor!;
    final sort = s.sort;

    state = FeedReady(
      posts: s.posts,
      sort: sort,
      hasMore: s.hasMore,
      nextCursor: s.nextCursor,
      loadingMore: true,
    );

    final useCase = ref.read(loadMoreFeedUseCaseProvider);
    final result = await useCase(cursor: cursor, sort: sort);

    switch (result) {
      case Ok(:final value):
        if (value.isEmpty) {
          state = FeedReady(
            posts: s.posts,
            sort: sort,
            hasMore: false,
            nextCursor: null,
            loadingMore: false,
          );
          return true;
        }
        final merged = _mergePosts(s.posts, value);
        final last = value.last;
        final pageHasMore = value.length >= FeedReady.pageSize;
        final next = pageHasMore
            ? FeedCursor(createdAt: last.createdAt, id: last.id.value)
            : null;
        state = FeedReady(
          posts: merged,
          sort: sort,
          hasMore: pageHasMore,
          nextCursor: next,
          loadingMore: false,
        );
        return true;
      case Err():
        state = FeedReady(
          posts: s.posts,
          sort: sort,
          hasMore: s.hasMore,
          nextCursor: s.nextCursor,
          loadingMore: false,
        );
        return false;
    }
  }

  static List<FeedPost> _mergePosts(
    List<FeedPost> existing,
    List<FeedPost> page,
  ) {
    final seen = existing.map((e) => e.id.value).toSet();
    final out = List<FeedPost>.from(existing);
    for (final p in page) {
      if (seen.add(p.id.value)) {
        out.add(p);
      }
    }
    return out;
  }

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
          loadingMore: false,
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

final feedNotifierProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
