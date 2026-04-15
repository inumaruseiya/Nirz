import 'package:flutter/material.dart';

import '../../domain/value_objects/reaction_type.dart';
import '../theme/app_tokens.dart';

/// 3 種リアクションの選択 UI（実装計画 Phase 8-2-1、詳細設計 6・4.5）。
///
/// `SegmentedButton` ではなくピル型のカスタム行にし、同じ選択を再度タップすると解除する。
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// 現在の選択。未リアクションは null。
  final ReactionType? selected;

  /// 選択が変わったとき。解除時は null。
  final ValueChanged<ReactionType?> onChanged;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget pill(ReactionType type, String emoji, String semanticsLabel) {
      final isOn = selected == type;
      return Expanded(
        child: Semantics(
          button: true,
          selected: isOn,
          label: semanticsLabel,
          child: Material(
            color: isOn ? cs.primaryContainer : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            child: InkWell(
              onTap: enabled
                  ? () {
                      if (selected == type) {
                        onChanged(null);
                      } else {
                        onChanged(type);
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              child: SizedBox(
                height: AppTokens.minTapTarget,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Row(
      children: [
        const SizedBox(width: AppTokens.spaceUnit / 2),
        pill(ReactionType.like, '👍', 'いいね'),
        SizedBox(width: AppTokens.spaceUnit),
        pill(ReactionType.look, '👀', '見た'),
        SizedBox(width: AppTokens.spaceUnit),
        pill(ReactionType.fire, '🔥', 'アツい'),
        const SizedBox(width: AppTokens.spaceUnit / 2),
      ],
    );

    final picker = Semantics(
      label: 'リアクション。いいね、見た、アツいから選べます',
      container: true,
      child: row,
    );

    if (enabled) {
      return picker;
    }

    return Opacity(opacity: 0.45, child: IgnorePointer(child: picker));
  }
}
