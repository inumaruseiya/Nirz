import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// フィード初回読み込み用のプレースホルダー（実装計画 Phase 6-3-5、詳細設計 5.1）。
class FeedSkeletonCard extends StatelessWidget {
  const FeedSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.screenHorizontalInset,
        vertical: AppTokens.spaceUnit / 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _bone(height: 20, color: color)),
                const SizedBox(width: AppTokens.spaceUnit),
                _bone(width: 56, height: 14, color: color),
              ],
            ),
            const SizedBox(height: AppTokens.spaceUnit / 2),
            _bone(width: 96, height: 12, color: color),
            const SizedBox(height: AppTokens.spaceUnit),
            _bone(height: 14, color: color),
            const SizedBox(height: AppTokens.spaceUnit / 2),
            _bone(height: 14, width: 200, color: color),
            const SizedBox(height: AppTokens.spaceUnit * 1.5),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceUnit * 1.5),
            Row(
              children: [
                _bone(width: 18, height: 18, color: color),
                const SizedBox(width: AppTokens.spaceUnit / 2),
                _bone(width: 18, height: 18, color: color),
                const SizedBox(width: AppTokens.spaceUnit / 2),
                _bone(width: 18, height: 18, color: color),
                const SizedBox(width: AppTokens.spaceUnit),
                _bone(width: 24, height: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _bone({required double height, required Color color, double? width}) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppTokens.radiusSurface / 2),
    ),
  );
}
