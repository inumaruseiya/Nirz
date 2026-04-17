import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/feed_post.dart';
import 'distance_label.dart';
import 'relative_time.dart';
import '../theme/app_tokens.dart';

/// shadcn/ui Card スタイルのフィードカード。
class LocalPostCard extends StatelessWidget {
  const LocalPostCard({super.key, required this.post, this.onTap});

  final FeedPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final distanceText = DistanceLabel.format(post.distanceKm);
    final relative     = formatRelativeTimeJa(post.createdAt);

    final card = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceUnit * 2,
        vertical:   AppTokens.spaceUnit,
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header: Avatar + Name + Time ──────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Avatar(name: name, size: 36),
                    const SizedBox(width: AppTokens.spaceUnit * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (distanceText != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  distanceText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceUnit),
                    Text(
                      relative,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // ── Separator ─────────────────────────────────────
                const SizedBox(height: AppTokens.spaceUnit * 1.5),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppTokens.spaceUnit * 1.5),

                // ── Content ───────────────────────────────────────
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),

                // ── Image ─────────────────────────────────────────
                if (post.imageUrl != null) ...[
                  const SizedBox(height: AppTokens.spaceUnit * 1.5),
                  _PostImage(imageUrl: post.imageUrl!.toString()),
                ],

                // ── Footer: Reactions ─────────────────────────────
                const SizedBox(height: AppTokens.spaceUnit * 1.5),
                _ReactionRow(count: post.reactionCount),
              ],
            ),
          ),
        ),
      ),
    );

    final reactionLabel = post.reactionCount == 0
        ? 'リアクションなし'
        : 'リアクション合計 ${post.reactionCount} 件';
    final imageSummary = post.imageUrl != null ? '画像あり。' : '';

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label:
          '$name、$relative'
          '${distanceText != null ? '、$distanceText' : ''}。'
          '${post.content}。$imageSummary$reactionLabel',
      child: card,
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  String get _initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:  scheme.primary.withValues(alpha: 0.12),
        shape:  BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize:   size * 0.42,
          fontWeight: FontWeight.w600,
          color:      scheme.primary,
          height:     1,
        ),
      ),
    );
  }
}

// ── Post Image ────────────────────────────────────────────────────────

class _PostImage extends StatelessWidget {
  const _PostImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr    = MediaQuery.devicePixelRatioOf(context);
        final logW   = constraints.maxWidth;
        final memW   = (logW * dpr).round().clamp(1, 4096);
        final memH   = ((logW * 9 / 16) * dpr).round().clamp(1, 4096);
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit:      BoxFit.cover,
              memCacheWidth:  memW,
              memCacheHeight: memH,
              placeholder: (_, __) => ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: const Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: scheme.onSurfaceVariant,
                  size: 36,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Reaction Row ─────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted  = scheme.onSurfaceVariant;
    final style  = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w500,
    );
    const iconSize = 15.0;

    return Row(
      children: [
        Icon(Icons.thumb_up_outlined,            size: iconSize, color: muted),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Icon(Icons.visibility_outlined,          size: iconSize, color: muted),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Icon(Icons.local_fire_department_outlined, size: iconSize, color: muted),
        const SizedBox(width: AppTokens.spaceUnit),
        Text('$count', style: style),
        const Spacer(),
        Icon(Icons.chat_bubble_outline, size: iconSize, color: muted),
      ],
    );
  }
}
