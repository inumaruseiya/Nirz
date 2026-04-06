import 'package:flutter/material.dart';

import '../../domain/value_objects/reaction_type.dart';
import '../theme/app_tokens.dart';

/// 3 種リアクションの選択 UI（実装計画 Phase 8-2-1、詳細設計 6・4.5）。
///
/// Material 3 の `SegmentedButton` で 👍 / 👀 / 🔥 を並べ、選択中をトーンでハイライトする。
///
/// [selected] が null のときは未選択。[emptySelectionAllowed] により同じ種を再度タップすると
/// 選択解除され [onChanged] に null が渡る（8-2-2 で Remove と組み合わせ可能）。
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

    final button = SegmentedButton<ReactionType>(
      showSelectedIcon: false,
      emptySelectionAllowed: true,
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
        minimumSize: const WidgetStatePropertyAll(
          Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(color: cs.outlineVariant),
        ),
      ),
      segments: [
        ButtonSegment<ReactionType>(
          value: ReactionType.like,
          label: const Text('👍', semanticsLabel: 'いいね'),
          tooltip: 'いいね',
        ),
        ButtonSegment<ReactionType>(
          value: ReactionType.look,
          label: const Text('👀', semanticsLabel: '見た'),
          tooltip: '見た',
        ),
        ButtonSegment<ReactionType>(
          value: ReactionType.fire,
          label: const Text('🔥', semanticsLabel: 'アツい'),
          tooltip: 'アツい',
        ),
      ],
      selected: selected == null ? <ReactionType>{} : <ReactionType>{selected!},
      onSelectionChanged: enabled
          ? (Set<ReactionType> next) {
              onChanged(next.isEmpty ? null : next.single);
            }
          : null,
    );

    final picker = Semantics(
      label: 'リアクション。いいね、見た、アツいから選べます',
      child: button,
    );

    if (enabled) {
      return picker;
    }

    return Opacity(
      opacity: 0.45,
      child: IgnorePointer(child: picker),
    );
  }
}
