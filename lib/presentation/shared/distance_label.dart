import 'package:flutter/material.dart';

/// 「約 x km」表示。`kilometers` が null または負のときは [SizedBox.shrink]（実装計画 Phase 6-2-2、詳細設計 6）。
class DistanceLabel extends StatelessWidget {
  const DistanceLabel({
    super.key,
    required this.kilometers,
    this.style,
  });

  final double? kilometers;
  final TextStyle? style;

  /// 表示用文言。非表示のときは null。
  static String? format(double? kilometers) {
    if (kilometers == null || kilometers < 0) return null;
    final rounded = kilometers >= 10
        ? kilometers.round().toString()
        : kilometers.toStringAsFixed(1);
    return '約 $rounded km';
  }

  @override
  Widget build(BuildContext context) {
    final text = format(kilometers);
    if (text == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Text(
      text,
      style: style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
}
