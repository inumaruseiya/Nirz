import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/feed_post.dart';
import 'distance_label.dart';
import 'relative_time.dart';
import '../theme/app_tokens.dart';

/// フィード 1 件のカード（実装計画 Phase 6-2-1、詳細設計 6・4.3）。
///
/// [immersive] が true のときは縦 PageView 用の全画面寄りレイアウト（画像は [BoxFit.cover]）。
class LocalPostCard extends StatelessWidget {
  const LocalPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.immersive = false,
  });

  final FeedPost post;
  final VoidCallback? onTap;

  /// true のとき BeReal 風のフルブリード＋下部グラデーションオーバーレイ。
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    if (immersive) {
      return _buildImmersive(context);
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final distanceText = DistanceLabel.format(post.distanceKm);
    final relative = formatRelativeTimeJa(post.createdAt);

    final card = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenHorizontalInset,
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
              Text(post.content, style: theme.textTheme.bodyLarge),
              if (post.imageUrl != null) ...[
                const SizedBox(height: AppTokens.spaceUnit * 1.5),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    final logicalW = constraints.maxWidth;
                    final memW = (logicalW * dpr).round().clamp(1, 4096);
                    final memH = ((logicalW * 9 / 16) * dpr).round().clamp(
                      1,
                      4096,
                    );
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppTokens.radiusSurface,
                      ),
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
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
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
              const SizedBox(height: AppTokens.spaceUnit * 1.5),
              _ReactionSummaryRow(count: post.reactionCount),
            ],
          ),
        ),
      ),
    );

    return _wrapSemantics(context, card);
  }

  Widget _buildImmersive(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final distanceText = DistanceLabel.format(post.distanceKm);
    final relative = formatRelativeTimeJa(post.createdAt);
    final bottomPad =
        AppTokens.feedImmersiveBottomPadding +
        MediaQuery.paddingOf(context).bottom;
    const overlayFg = Color(0xE6FFFFFF);

    final body = Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final memW = (w * dpr).round().clamp(1, 4096);
            final memH = (h * dpr).round().clamp(1, 4096);

            return Stack(
              fit: StackFit.expand,
              children: [
                if (post.imageUrl != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!.toString(),
                      fit: BoxFit.cover,
                      width: w,
                      height: h,
                      memCacheWidth: memW,
                      memCacheHeight: memH,
                      placeholder: (context, url) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: Center(
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 72,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height:
                      AppTokens.feedImmersiveGradientHeight +
                      MediaQuery.paddingOf(context).bottom,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppTokens.screenHorizontalInset,
                  right: AppTokens.screenHorizontalInset,
                  bottom: bottomPad,
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: overlayFg,
                      height: 1.35,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: overlayFg,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceUnit),
                            Text(
                              relative,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: overlayFg.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(height: AppTokens.spaceUnit / 2),
                          DistanceLabel(
                            kilometers: post.distanceKm,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: overlayFg.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTokens.spaceUnit),
                        Text(
                          post.content,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTokens.spaceUnit),
                        _ReactionSummaryRow(
                          count: post.reactionCount,
                          foreground: overlayFg.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    return _wrapSemantics(context, body);
  }

  Widget _wrapSemantics(BuildContext context, Widget child) {
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : '近くのユーザー';
    final distanceText = DistanceLabel.format(post.distanceKm);
    final relative = formatRelativeTimeJa(post.createdAt);
    final reactionLabel = post.reactionCount == 0
        ? 'リアクションなし'
        : 'リアクション合計 ${post.reactionCount} 件（いいね・見た・炎の合計）';
    final imageSummary = post.imageUrl != null ? '画像あり。' : '';

    return Semantics(
      button: onTap != null,
      excludeSemantics: true,
      label:
          '$name、$relative${distanceText != null ? '、$distanceText' : ''}。${post.content}。$imageSummary$reactionLabel',
      child: child,
    );
  }
}

class _ReactionSummaryRow extends StatelessWidget {
  const _ReactionSummaryRow({required this.count, this.foreground});

  final int count;
  final Color? foreground;

  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = foreground ?? theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelLarge?.copyWith(color: color);

    return Row(
      children: [
        Icon(Icons.thumb_up_outlined, size: _iconSize, color: color),
        const SizedBox(width: AppTokens.spaceUnit / 2),
        Icon(Icons.visibility_outlined, size: _iconSize, color: color),
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
