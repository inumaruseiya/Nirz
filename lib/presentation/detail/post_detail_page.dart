import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/reaction_type.dart';
import '../shared/distance_label.dart';
import '../shared/error_retry_panel.dart';
import '../shared/location_permission_callout.dart';
import '../shared/reaction_picker.dart';
import '../shared/relative_time.dart';
import '../theme/app_tokens.dart';
import 'post_detail_notifier.dart';

/// 投稿画像を全画面表示（実装計画 Phase 8-1-3）。ピンチで拡大縮小、背景タップまたは閉じるで戻る。
void showPostDetailImageViewer(BuildContext context, String imageUrl) {
  final barrierLabel =
      MaterialLocalizations.of(context).modalBarrierDismissLabel;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: '投稿画像の拡大表示。ピンチで拡大縮小。画面外をタップするか閉じるで戻ります。',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.broken_image_outlined,
                        color: Theme.of(dialogContext).colorScheme.onSurface,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceUnit),
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: '閉じる',
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// 投稿詳細（実装計画 Phase 8-1-1、詳細設計 4.5）。
///
/// 状態は [PostDetailNotifier]（Phase 8-1-2）。コメント・[ReactionPicker]・削除メニューは後続タスク。
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailState = ref.watch(postDetailNotifierProvider(postId));
    final sessionAsync = ref.watch(sessionStateProvider);

    ref.listen<PostDetailState>(
      postDetailNotifierProvider(postId),
      (previous, next) {
        if (next is PostDetailDeleted && context.mounted) {
          context.pop(true);
        }
      },
    );

    final postForOwnerCheck = switch (detailState) {
      PostDetailReady(:final post) => post,
      PostDetailDeleting(:final post) => post,
      _ => null,
    };
    final isOwner = switch (sessionAsync) {
      AsyncData(:final value) => switch (value) {
          SessionSignedIn(:final userId) =>
            postForOwnerCheck != null &&
                userId.value == postForOwnerCheck.authorId.value,
          _ => false,
        },
      _ => false,
    };

    final showDeleteMenu = isOwner && detailState is PostDetailReady;

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
        actions: [
          if (showDeleteMenu)
            PopupMenuButton<String>(
              tooltip: 'その他',
              onSelected: (value) async {
                if (value != 'delete') return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('投稿を削除'),
                    content: const Text(
                      'この投稿を削除しますか？この操作は取り消せません。',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final err = await ref
                    .read(postDetailNotifierProvider(postId).notifier)
                    .deletePost();
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('削除'),
                ),
              ],
            ),
        ],
      ),
      body: switch (detailState) {
        PostDetailInvalidId() => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '無効な投稿 ID です',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        PostDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        PostDetailLocationDenied() => Center(
            child: LocationPermissionCallout(
              onOpenSettings: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        PostDetailError(:final message) => Center(
            child: ErrorRetryPanel(
              message: message,
              onRetry: () => ref
                  .read(postDetailNotifierProvider(postId).notifier)
                  .reload(),
            ),
          ),
        PostDetailNotFound() => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'この投稿は表示できません（範囲外・削除済み・期限切れの可能性があります）',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.spaceUnit * 2),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            ),
          ),
        PostDetailReady(
          :final post,
          :final myReactionType,
          :final reactionSending,
        ) =>
          _PostDetailBody(
            child: _PostDetailContent(
              post: post,
              myReactionType: myReactionType,
              reactionPickerEnabled: !reactionSending,
              onReactionSelected: (next) async {
                final err = await ref
                    .read(postDetailNotifierProvider(postId).notifier)
                    .applyReactionSelection(next);
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              },
            ),
          ),
        PostDetailDeleting(:final post, :final myReactionType) =>
          _PostDetailBody(
            child: _PostDetailContent(
              post: post,
              myReactionType: myReactionType,
              reactionPickerEnabled: false,
              onReactionSelected: (_) async {},
            ),
            blocking: true,
          ),
        PostDetailDeleted() => const Center(
            child: CircularProgressIndicator(),
          ),
      },
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({
    required this.child,
    this.blocking = false,
  });

  final Widget child;
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (blocking)
          const ModalBarrier(
            dismissible: false,
            color: Color(0x33000000),
          ),
        if (blocking)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({
    required this.post,
    required this.myReactionType,
    required this.reactionPickerEnabled,
    required this.onReactionSelected,
  });

  final FeedPost post;
  final ReactionType? myReactionType;
  final bool reactionPickerEnabled;
  final ValueChanged<ReactionType?> onReactionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final relative = formatRelativeTimeJa(post.createdAt);
    final distanceText = DistanceLabel.format(post.distanceKm);
    final commentLine = post.commentCount != null
        ? 'コメント ${post.commentCount} 件（Phase 9 で表示予定）'
        : null;

    final reactionLabel = post.reactionCount == 0
        ? 'リアクションなし'
        : 'リアクション合計 ${post.reactionCount} 件（いいね・見た・炎の合計）';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
      child: Semantics(
        label:
            '$name、$relative${distanceText != null ? '、$distanceText' : ''}。${post.content}。$reactionLabel',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: AppTokens.spaceUnit),
                Text(
                  relative,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (distanceText != null) ...[
              const SizedBox(height: AppTokens.spaceUnit / 2),
              DistanceLabel(kilometers: post.distanceKm),
            ],
            const SizedBox(height: AppTokens.spaceUnit * 2),
            Text(
              post.content,
              style: theme.textTheme.bodyLarge,
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: AppTokens.spaceUnit * 2),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dpr = MediaQuery.devicePixelRatioOf(context);
                  final logicalW = constraints.maxWidth;
                  final memW = (logicalW * dpr).round().clamp(1, 4096);
                  final memH =
                      ((logicalW * 9 / 16) * dpr).round().clamp(1, 4096);
                  final url = post.imageUrl!.toString();
                  return Semantics(
                    button: true,
                    label: '投稿画像。タップで拡大表示',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => showPostDetailImageViewer(context, url),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusSurface),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusSurface),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              memCacheWidth: memW,
                              memCacheHeight: memH,
                              placeholder: (context, u) => ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, u, error) => ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: AppTokens.spaceUnit * 2),
            ReactionPicker(
              selected: myReactionType,
              enabled: reactionPickerEnabled,
              onChanged: onReactionSelected,
            ),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            _DetailReactionSummaryRow(count: post.reactionCount),
            if (commentLine != null) ...[
              const SizedBox(height: AppTokens.spaceUnit * 2),
              Text(
                commentLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailReactionSummaryRow extends StatelessWidget {
  const _DetailReactionSummaryRow({required this.count});

  final int count;

  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.titleSmall?.copyWith(color: color);

    return Row(
      children: [
        Icon(
          Icons.thumb_up_outlined,
          size: _iconSize,
          color: color,
        ),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Icon(
          Icons.visibility_outlined,
          size: _iconSize,
          color: color,
        ),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Icon(
          Icons.local_fire_department_outlined,
          size: _iconSize,
          color: color,
        ),
        const SizedBox(width: AppTokens.spaceUnit),
        Text('$count', style: style),
      ],
    );
  }
}
