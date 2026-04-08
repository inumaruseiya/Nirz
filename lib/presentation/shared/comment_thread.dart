import 'package:flutter/material.dart';

import '../../domain/entities/comment.dart';
import '../../domain/value_objects/comment_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../theme/app_tokens.dart';
import 'relative_time.dart';

/// コメントスレッド（実装計画 Phase 9-1-1、詳細設計 6・4.5）。
///
/// トップレベルコメントを列挙し、各項目の下に 1 階層の返信をインデント表示する。
/// トップレベルにのみ「返信」ボタンを出す（返信への返信は禁止のため）。
class CommentThread extends StatelessWidget {
  const CommentThread({
    super.key,
    required this.comments,
    this.resolveAuthorLabel,
    this.onReplyTo,
    this.viewerUserId,
    this.reportMenuEnabled = true,
    this.onReportComment,
    this.onBlockCommentAuthor,
  });

  /// 同一投稿に紐づくコメント一覧（`created_at` 昇順を想定）。
  final List<Comment> comments;

  /// 表示名。未指定時は「近くのユーザー」。
  final String Function(UserId authorId)? resolveAuthorLabel;

  /// トップレベルコメントの「返信」押下。返信行には出さない。
  final ValueChanged<CommentId>? onReplyTo;

  /// ログイン中の閲覧者。自分のコメントには「通報」を出さない（Phase 10-2-1）。
  final UserId? viewerUserId;

  /// 通報送信中などに false（Phase 10-2-3）。
  final bool reportMenuEnabled;

  /// 他人のコメントの「通報」押下（理由 UI + `reports` INSERT、Phase 10-2-2/3）。
  final Future<void> Function(CommentId)? onReportComment;

  /// コメント投稿者のブロック（Phase 10-3-2）。
  final Future<void> Function(UserId)? onBlockCommentAuthor;

  String _label(UserId id) =>
      resolveAuthorLabel?.call(id) ?? '近くのユーザー';

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    final tops = comments.where((c) => c.parentId == null).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final replyByParent = <CommentId, List<Comment>>{};
    for (final c in comments) {
      final p = c.parentId;
      if (p != null) {
        replyByParent.putIfAbsent(p, () => []).add(c);
      }
    }
    for (final list in replyByParent.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final topIds = tops.map((c) => c.id).toSet();
    for (final parentId in replyByParent.keys.toList()) {
      if (!topIds.contains(parentId)) {
        replyByParent.remove(parentId);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tops.length; i++) ...[
          if (i > 0) SizedBox(height: AppTokens.spaceUnit * 1.5),
          _TopLevelCommentBlock(
            comment: tops[i],
            authorLabel: _label(tops[i].authorId),
            replies: replyByParent[tops[i].id] ?? const [],
            replyAuthorLabel: _label,
            onReply: onReplyTo == null ? null : () => onReplyTo!(tops[i].id),
            viewerUserId: viewerUserId,
            reportMenuEnabled: reportMenuEnabled,
            onReportComment: onReportComment,
            onBlockCommentAuthor: onBlockCommentAuthor,
          ),
        ],
      ],
    );
  }
}

class _TopLevelCommentBlock extends StatelessWidget {
  const _TopLevelCommentBlock({
    required this.comment,
    required this.authorLabel,
    required this.replies,
    required this.replyAuthorLabel,
    this.onReply,
    this.viewerUserId,
    this.reportMenuEnabled = true,
    this.onReportComment,
    this.onBlockCommentAuthor,
  });

  final Comment comment;
  final String authorLabel;
  final List<Comment> replies;
  final String Function(UserId id) replyAuthorLabel;
  final VoidCallback? onReply;
  final UserId? viewerUserId;
  final bool reportMenuEnabled;
  final Future<void> Function(CommentId)? onReportComment;
  final Future<void> Function(UserId)? onBlockCommentAuthor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommentBody(
          comment: comment,
          authorLabel: authorLabel,
          viewerUserId: viewerUserId,
          reportMenuEnabled: reportMenuEnabled,
          onReportComment: onReportComment,
          onBlockCommentAuthor: onBlockCommentAuthor,
        ),
        if (onReply != null) ...[
          const SizedBox(height: AppTokens.spaceUnit / 2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              label: '返信',
              hint:
                  'このコメントに1階層だけ返信できます。返信コメントにさらに返信することはできません。',
              child: TextButton(
                onPressed: onReply,
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    AppTokens.minTapTarget,
                    AppTokens.minTapTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceUnit,
                  ),
                ),
                child: const Text('返信'),
              ),
            ),
          ),
        ],
        if (replies.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spaceUnit / 2),
          Semantics(
            label: '返信 ${replies.length} 件',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < replies.length; j++) ...[
                  if (j > 0) const SizedBox(height: AppTokens.spaceUnit),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: BorderSide(
                          width: 3,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppTokens.spaceUnit * 2,
                      ),
                      child: _CommentBody(
                        comment: replies[j],
                        authorLabel: replyAuthorLabel(replies[j].authorId),
                        viewerUserId: viewerUserId,
                        reportMenuEnabled: reportMenuEnabled,
                        onReportComment: onReportComment,
                        onBlockCommentAuthor: onBlockCommentAuthor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentBody extends StatelessWidget {
  const _CommentBody({
    required this.comment,
    required this.authorLabel,
    this.viewerUserId,
    this.reportMenuEnabled = true,
    this.onReportComment,
    this.onBlockCommentAuthor,
  });

  final Comment comment;
  final String authorLabel;
  final UserId? viewerUserId;
  final bool reportMenuEnabled;
  final Future<void> Function(CommentId)? onReportComment;
  final Future<void> Function(UserId)? onBlockCommentAuthor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relative = formatRelativeTimeJa(comment.createdAt);
    final semanticsLabel =
        '$authorLabel、$relative。${comment.content}';
    final showReport = reportMenuEnabled &&
        viewerUserId != null &&
        onReportComment != null &&
        comment.authorId.value != viewerUserId!.value;
    final showBlock = reportMenuEnabled &&
        viewerUserId != null &&
        onBlockCommentAuthor != null &&
        comment.authorId.value != viewerUserId!.value;
    final showOverflowMenu = showReport || showBlock;

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  authorLabel,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showOverflowMenu)
                Semantics(
                  button: true,
                  label: 'コメントのその他メニュー',
                  child: PopupMenuButton<String>(
                    tooltip: 'コメントのその他',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: AppTokens.minTapTarget,
                      minHeight: AppTokens.minTapTarget,
                    ),
                    icon: const Icon(Icons.more_vert, size: 22),
                    onSelected: (value) {
                      if (value == 'report') {
                        onReportComment?.call(comment.id);
                      } else if (value == 'block') {
                        onBlockCommentAuthor?.call(comment.authorId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (showReport)
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Text('通報'),
                        ),
                      if (showBlock)
                        const PopupMenuItem<String>(
                          value: 'block',
                          child: Text('このユーザーをブロック'),
                        ),
                    ],
                  ),
                ),
              Text(
                relative,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceUnit / 2),
          Text(
            comment.content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
