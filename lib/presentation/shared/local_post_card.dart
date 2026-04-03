import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/feed_post.dart';
import 'distance_label.dart';
import 'relative_time.dart';
import '../theme/app_tokens.dart';

/// フィード 1 件のカード（実装計画 Phase 6-2-1、詳細設計 6・4.3）。
class LocalPostCard extends StatelessWidget {
  const LocalPostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  final FeedPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final distanceText = DistanceLabel.format(post.distanceKm);
    final relative = formatRelativeTimeJa(post.createdAt);

    final card = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceUnit,
        vertical: AppTokens.spaceUnit / 2,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: AppTokens.spaceUnit),
              Text(
                post.content,
                style: theme.textTheme.bodyLarge,
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: AppTokens.spaceUnit * 1.5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!.toString(),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.spaceUnit * 1.5),
              _ReactionSummaryRow(count: post.reactionCount),
            ],
          ),
        ),
      ),
    );

    final reactionLabel = post.reactionCount == 0
        ? 'リアクションなし'
        : 'リアクション ${post.reactionCount} 件';

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label:
          '$name、$relative${distanceText != null ? '、$distanceText' : ''}。${post.content}。$reactionLabel',
      child: card,
    );
  }
}

class _ReactionSummaryRow extends StatelessWidget {
  const _ReactionSummaryRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Icon(
          Icons.favorite_outline,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
          semanticLabel: 'リアクション',
        ),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Text('$count', style: style),
      ],
    );
  }
}
