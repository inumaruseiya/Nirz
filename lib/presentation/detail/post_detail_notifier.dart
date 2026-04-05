import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/value_objects/post_id.dart';

/// 投稿詳細画面の状態（実装計画 Phase 8-1-2）。
///
/// 読み込み・リアクション・コメントはこの Notifier に集約する（リアクション等は後続タスクで拡張）。
sealed class PostDetailState {
  const PostDetailState();
}

/// ルート引数の投稿 ID が UUID として不正。
final class PostDetailInvalidId extends PostDetailState {
  const PostDetailInvalidId();
}

/// 初回・再読み込み中。
final class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

/// 位置権限・サービスにより閲覧者座標が取れない。
final class PostDetailLocationDenied extends PostDetailState {
  const PostDetailLocationDenied();
}

/// ネットワーク・認証・サーバー等。
final class PostDetailError extends PostDetailState {
  const PostDetailError(this.message);

  final String message;
}

/// RPC 上、該当投稿なし（範囲外・削除・期限切れなど）。
final class PostDetailNotFound extends PostDetailState {
  const PostDetailNotFound();
}

/// 表示可能。
final class PostDetailReady extends PostDetailState {
  const PostDetailReady(this.post);

  final FeedPost post;
}

/// [arg] はルートの生文字列（`GoRouter` の `postId`）。
final class PostDetailNotifier
    extends AutoDisposeFamilyNotifier<PostDetailState, String> {
  @override
  PostDetailState build(String postIdRaw) {
    try {
      PostId.parse(postIdRaw);
    } catch (_) {
      return const PostDetailInvalidId();
    }
    Future.microtask(_load);
    return const PostDetailLoading();
  }

  /// 再試行・明示リフレッシュ用。
  Future<void> reload() => _load();

  Future<void> _load() async {
    PostId id;
    try {
      id = PostId.parse(arg);
    } catch (_) {
      return;
    }

    state = const PostDetailLoading();

    final useCase = ref.read(loadPostDetailUseCaseProvider);
    final result = await useCase(id);

    switch (result) {
      case Ok(:final value):
        if (value.isEmpty) {
          state = const PostDetailNotFound();
        } else {
          state = PostDetailReady(value.first);
        }
      case Err(:final error):
        state = switch (error) {
          LocationFailure() => const PostDetailLocationDenied(),
          _ => PostDetailError(_messageForFailure(error)),
        };
    }
  }

  static String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() =>
        '接続できませんでした。通信環境を確認してください。',
      AuthFailure() =>
        'セッションの有効期限が切れました。再度ログインしてください。',
      ServerFailure() =>
        'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報を利用できません。',
    };
  }
}

final postDetailNotifierProvider = NotifierProvider.autoDispose
    .family<PostDetailNotifier, PostDetailState, String>(
  PostDetailNotifier.new,
);
