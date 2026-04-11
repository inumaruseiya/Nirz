import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/post_id.dart';
import '../../domain/value_objects/reaction_type.dart';
import '../../domain/value_objects/report_target_type.dart';
import '../../domain/value_objects/user_id.dart';

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
  const PostDetailReady(
    this.post, {
    this.myReactionType,
    this.reactionSending = false,
    this.reportSubmitting = false,
    this.blockSubmitting = false,
    this.comments = const [],
    this.commentsLoading = false,
    this.commentsError,
  });

  final FeedPost post;

  /// ログインユーザーのこの投稿へのリアクション（未取得・エラー時は null）。
  final ReactionType? myReactionType;

  /// リアクション API 送信中（[ReactionPicker] 無効化用）。
  final bool reactionSending;

  /// 通報送信中（Phase 10-2-3）。
  final bool reportSubmitting;

  /// ブロック送信中（Phase 10-3-2）。
  final bool blockSubmitting;

  /// [LoadCommentsUseCase] で取得したコメント（実装計画 Phase 9-1-3）。
  final List<Comment> comments;

  /// コメント一覧取得中。
  final bool commentsLoading;

  /// コメント取得失敗時のユーザー向け文言。再試行で null に戻す。
  final String? commentsError;
}

/// 削除 API 送信中（同じ内容を表示しつつ操作を抑止）。
final class PostDetailDeleting extends PostDetailState {
  const PostDetailDeleting(
    this.post, {
    this.myReactionType,
    this.reportSubmitting = false,
    this.blockSubmitting = false,
    this.comments = const [],
    this.commentsLoading = false,
    this.commentsError,
  });

  final FeedPost post;
  final ReactionType? myReactionType;

  /// 削除待ち中に通報送信が走っていた場合に引き継ぐ（通常は false）。
  final bool reportSubmitting;

  /// 削除待ち中にブロック送信が走っていた場合に引き継ぐ（通常は false）。
  final bool blockSubmitting;

  final List<Comment> comments;
  final bool commentsLoading;
  final String? commentsError;
}

/// 削除成功。画面は `pop(true)` で閉じる（フィード更新用）。
final class PostDetailDeleted extends PostDetailState {
  const PostDetailDeleted();
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

  /// コメント一覧のみ再取得（Phase 9-1-3）。投稿表示後の再試行用。
  Future<void> reloadComments() async {
    PostId id;
    try {
      id = PostId.parse(arg);
    } catch (_) {
      return;
    }
    await _loadComments(postId: id);
  }

  /// トップレベルコメント投稿（Phase 9-1-4、[AddCommentUseCase]）。
  ///
  /// 成功時は一覧末尾にマージし、[FeedPost.commentCount] があれば +1。失敗時はユーザー向け文言を返す。
  Future<String?> submitTopLevelComment(String content) async {
    final cur = state;
    if (cur is! PostDetailReady ||
        cur.reportSubmitting ||
        cur.blockSubmitting) {
      return null;
    }

    final postId = cur.post.id;
    final result = await ref.read(addCommentUseCaseProvider)(
      postId: postId,
      content: content,
    );

    final after = state;
    if (after is! PostDetailReady) return null;

    switch (result) {
      case Ok(:final value):
        final merged = _mergeCommentsSorted(after.comments, value);
        final nextPost = _feedPostWithCommentCountDelta(after.post, 1);
        state = PostDetailReady(
          nextPost,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: after.reportSubmitting,
          blockSubmitting: after.blockSubmitting,
          comments: merged,
          commentsLoading: after.commentsLoading,
          commentsError: null,
        );
        return null;
      case Err(:final error):
        return _messageForFailure(error);
    }
  }

  /// 1 階層返信（Phase 9-1-5、[AddReplyUseCase]）。親はトップレベルコメントのみ（9-1-6: UseCase と二重検証）。
  Future<String?> submitReply({
    required CommentId parentId,
    required String content,
  }) async {
    final cur = state;
    if (cur is! PostDetailReady ||
        cur.reportSubmitting ||
        cur.blockSubmitting) {
      return null;
    }

    Comment? parent;
    for (final c in cur.comments) {
      if (c.id == parentId) {
        parent = c;
        break;
      }
    }
    if (parent == null) {
      return '対象のコメントが見つかりません。';
    }
    if (!parent.isTopLevelComment) {
      return '返信の返信はできません。トップレベルのコメントにのみ返信できます。';
    }

    final postId = cur.post.id;
    final result = await ref.read(addReplyUseCaseProvider)(
      postId: postId,
      parentId: parentId,
      content: content,
    );

    final after = state;
    if (after is! PostDetailReady) return null;

    switch (result) {
      case Ok(:final value):
        final merged = _mergeCommentsSorted(after.comments, value);
        final nextPost = _feedPostWithCommentCountDelta(after.post, 1);
        state = PostDetailReady(
          nextPost,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: after.reportSubmitting,
          blockSubmitting: after.blockSubmitting,
          comments: merged,
          commentsLoading: after.commentsLoading,
          commentsError: null,
        );
        return null;
      case Err(:final error):
        return _messageForFailure(error);
    }
  }

  /// 通報を送信（Phase 10-2-3、[SubmitReportUseCase]）。
  Future<String?> submitReport(ReportSubmission submission) async {
    final cur = state;
    if (cur is! PostDetailReady ||
        cur.reactionSending ||
        cur.reportSubmitting ||
        cur.blockSubmitting) {
      return null;
    }

    state = PostDetailReady(
      cur.post,
      myReactionType: cur.myReactionType,
      reactionSending: cur.reactionSending,
      reportSubmitting: true,
      blockSubmitting: cur.blockSubmitting,
      comments: cur.comments,
      commentsLoading: cur.commentsLoading,
      commentsError: cur.commentsError,
    );

    final result = await ref.read(submitReportUseCaseProvider)(submission);

    final after = state;
    if (after is! PostDetailReady) return null;

    switch (result) {
      case Ok():
        state = PostDetailReady(
          after.post,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: false,
          blockSubmitting: after.blockSubmitting,
          comments: after.comments,
          commentsLoading: after.commentsLoading,
          commentsError: after.commentsError,
        );
        return null;
      case Err(:final error):
        state = PostDetailReady(
          after.post,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: false,
          blockSubmitting: after.blockSubmitting,
          comments: after.comments,
          commentsLoading: after.commentsLoading,
          commentsError: after.commentsError,
        );
        return _messageForFailure(error);
    }
  }

  /// ユーザーをブロック（Phase 10-3-2、[BlockUserUseCase]）。
  Future<String?> blockUser(UserId blockedUserId) async {
    final cur = state;
    if (cur is! PostDetailReady ||
        cur.reactionSending ||
        cur.reportSubmitting ||
        cur.blockSubmitting) {
      return null;
    }

    state = PostDetailReady(
      cur.post,
      myReactionType: cur.myReactionType,
      reactionSending: cur.reactionSending,
      reportSubmitting: cur.reportSubmitting,
      blockSubmitting: true,
      comments: cur.comments,
      commentsLoading: cur.commentsLoading,
      commentsError: cur.commentsError,
    );

    final result = await ref.read(blockUserUseCaseProvider)(blockedUserId);

    final after = state;
    if (after is! PostDetailReady) return null;

    switch (result) {
      case Ok():
        state = PostDetailReady(
          after.post,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: after.reportSubmitting,
          blockSubmitting: false,
          comments: after.comments,
          commentsLoading: after.commentsLoading,
          commentsError: after.commentsError,
        );
        return null;
      case Err(:final error):
        state = PostDetailReady(
          after.post,
          myReactionType: after.myReactionType,
          reactionSending: after.reactionSending,
          reportSubmitting: after.reportSubmitting,
          blockSubmitting: false,
          comments: after.comments,
          commentsLoading: after.commentsLoading,
          commentsError: after.commentsError,
        );
        return _messageForFailure(error);
    }
  }

  /// 自分の投稿の削除。成功時は [PostDetailDeleted]、失敗時は元の [PostDetailReady] に戻し、エラー文言を返す。
  Future<String?> deletePost() async {
    final current = state;
    if (current is! PostDetailReady ||
        current.reportSubmitting ||
        current.blockSubmitting) {
      return null;
    }
    final post = current.post;
    final myReactionType = current.myReactionType;

    state = PostDetailDeleting(
      post,
      myReactionType: myReactionType,
      reportSubmitting: current.reportSubmitting,
      blockSubmitting: current.blockSubmitting,
      comments: current.comments,
      commentsLoading: current.commentsLoading,
      commentsError: current.commentsError,
    );

    final useCase = ref.read(deletePostUseCaseProvider);
    final result = await useCase(post.id);

    switch (result) {
      case Ok():
        state = const PostDetailDeleted();
        return null;
      case Err(:final error):
        state = PostDetailReady(
          post,
          myReactionType: myReactionType,
          reportSubmitting: false,
          blockSubmitting: false,
          comments: current.comments,
          commentsLoading: current.commentsLoading,
          commentsError: current.commentsError,
        );
        return _messageForFailure(error);
    }
  }

  /// [ReactionPicker] からの選択。楽観的に件数更新し、失敗時はロールバックしてエラー文言を返す（8-2-2 / 8-2-3）。
  Future<String?> applyReactionSelection(ReactionType? nextType) async {
    final cur = state;
    if (cur is! PostDetailReady ||
        cur.reactionSending ||
        cur.reportSubmitting ||
        cur.blockSubmitting) {
      return null;
    }

    final before = cur;
    final prevType = before.myReactionType;
    if (prevType == nextType) return null;

    final postId = before.post.id;
    final delta = _reactionCountDelta(prevType, nextType);
    final optimisticPost = _feedPostWithReactionDelta(before.post, delta);

    state = PostDetailReady(
      optimisticPost,
      myReactionType: nextType,
      reactionSending: true,
      reportSubmitting: before.reportSubmitting,
      blockSubmitting: before.blockSubmitting,
      comments: before.comments,
      commentsLoading: before.commentsLoading,
      commentsError: before.commentsError,
    );

    final Result<void, Failure> result;
    if (nextType == null) {
      result = await ref.read(removeReactionUseCaseProvider)(postId);
    } else {
      result = await ref.read(submitReactionUseCaseProvider)(postId, nextType);
    }

    final afterCall = state;
    if (afterCall is! PostDetailReady) return null;

    switch (result) {
      case Ok():
        state = PostDetailReady(
          afterCall.post,
          myReactionType: nextType,
          reportSubmitting: afterCall.reportSubmitting,
          blockSubmitting: afterCall.blockSubmitting,
          comments: afterCall.comments,
          commentsLoading: afterCall.commentsLoading,
          commentsError: afterCall.commentsError,
        );
        return null;
      case Err(:final error):
        state = PostDetailReady(
          before.post,
          myReactionType: prevType,
          reportSubmitting: before.reportSubmitting,
          blockSubmitting: before.blockSubmitting,
          comments: before.comments,
          commentsLoading: before.commentsLoading,
          commentsError: before.commentsError,
        );
        return _messageForFailure(error);
    }
  }

  static int _reactionCountDelta(ReactionType? prev, ReactionType? next) {
    if (prev == null && next != null) return 1;
    if (prev != null && next == null) return -1;
    return 0;
  }

  static FeedPost _feedPostWithReactionDelta(FeedPost p, int delta) {
    final next = p.reactionCount + delta;
    return FeedPost(
      post: p.post,
      reactionCount: next < 0 ? 0 : next,
      authorName: p.authorName,
      distanceKm: p.distanceKm,
      commentCount: p.commentCount,
    );
  }

  static FeedPost _feedPostWithCommentCountDelta(FeedPost p, int delta) {
    final c = p.commentCount;
    final next = c == null ? null : c + delta;
    return FeedPost(
      post: p.post,
      reactionCount: p.reactionCount,
      authorName: p.authorName,
      distanceKm: p.distanceKm,
      commentCount: next != null && next < 0 ? 0 : next,
    );
  }

  static List<Comment> _mergeCommentsSorted(
    List<Comment> existing,
    Comment added,
  ) {
    final out = [...existing, added];
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

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
          final feedPost = value.first;
          final myRx = ref.read(getMyReactionUseCaseProvider);
          final myResult = await myRx(feedPost.id);
          final ReactionType? myType = switch (myResult) {
            Ok(:final value) => value?.type,
            Err() => null,
          };
          state = PostDetailReady(
            feedPost,
            myReactionType: myType,
            reportSubmitting: false,
            blockSubmitting: false,
            comments: const [],
            commentsLoading: true,
          );
          unawaited(_loadComments(postId: id));
        }
      case Err(:final error):
        state = switch (error) {
          LocationFailure() => const PostDetailLocationDenied(),
          _ => PostDetailError(_messageForFailure(error)),
        };
    }
  }

  Future<void> _loadComments({required PostId postId}) async {
    _patchCommentFields(
      comments: _currentCommentsIfSamePost(postId),
      loading: true,
      error: null,
    );

    final result = await ref.read(loadCommentsUseCaseProvider)(postId);

    if (!_isSamePostReadyOrDeleting(postId)) return;

    switch (result) {
      case Ok(:final value):
        _patchCommentFields(comments: value, loading: false, error: null);
      case Err(:final error):
        _patchCommentFields(
          comments: _currentCommentsIfSamePost(postId),
          loading: false,
          error: _messageForFailure(error),
        );
    }
  }

  bool _isSamePostReadyOrDeleting(PostId postId) {
    final s = state;
    return switch (s) {
      PostDetailReady(:final post) => post.id == postId,
      PostDetailDeleting(:final post) => post.id == postId,
      _ => false,
    };
  }

  List<Comment> _currentCommentsIfSamePost(PostId postId) {
    final s = state;
    return switch (s) {
      PostDetailReady(:final post, :final comments) when post.id == postId =>
        comments,
      PostDetailDeleting(:final post, :final comments) when post.id == postId =>
        comments,
      _ => const [],
    };
  }

  void _patchCommentFields({
    required List<Comment> comments,
    required bool loading,
    String? error,
  }) {
    final s = state;
    switch (s) {
      case PostDetailReady():
        state = PostDetailReady(
          s.post,
          myReactionType: s.myReactionType,
          reactionSending: s.reactionSending,
          reportSubmitting: s.reportSubmitting,
          blockSubmitting: s.blockSubmitting,
          comments: comments,
          commentsLoading: loading,
          commentsError: error,
        );
      case PostDetailDeleting():
        state = PostDetailDeleting(
          s.post,
          myReactionType: s.myReactionType,
          reportSubmitting: s.reportSubmitting,
          blockSubmitting: s.blockSubmitting,
          comments: comments,
          commentsLoading: loading,
          commentsError: error,
        );
      default:
        break;
    }
  }

  static String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() => '接続できませんでした。通信環境を確認してください。',
      AuthFailure() => 'セッションの有効期限が切れました。再度ログインしてください。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報を利用できません。',
    };
  }
}

final postDetailNotifierProvider = NotifierProvider.autoDispose
    .family<PostDetailNotifier, PostDetailState, String>(
      PostDetailNotifier.new,
    );
