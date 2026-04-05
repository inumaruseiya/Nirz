import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/feed_post.dart';
import '../shared/distance_label.dart';
import '../shared/error_retry_panel.dart';
import '../shared/location_permission_callout.dart';
import '../shared/relative_time.dart';
import '../theme/app_tokens.dart';
import 'post_detail_notifier.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
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
        PostDetailReady(:final post) => _PostDetailContent(post: post),
      },
    );
  }
}

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({required this.post});

  final FeedPost post;

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
                  return ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusSurface),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!.toString(),
                        fit: BoxFit.cover,
                        memCacheWidth: memW,
                        memCacheHeight: memH,
                        placeholder: (context, url) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
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
