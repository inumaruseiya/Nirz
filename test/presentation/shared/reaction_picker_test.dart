import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';
import 'package:nirz/presentation/shared/reaction_picker.dart';

void main() {
  group('ReactionPicker', () {
    testWidgets('未選択からいいねを選ぶと onChanged が like を渡す', (tester) async {
      ReactionType? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(selected: null, onChanged: (v) => last = v),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('いいね'));
      await tester.pump();

      expect(last, ReactionType.like);
    });

    testWidgets('いいね選択中に同じセグメントをタップすると解除（null）', (tester) async {
      ReactionType? last = ReactionType.like;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReactionPicker(
                  selected: last,
                  onChanged: (v) => setState(() => last = v),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('いいね'));
      await tester.pump();

      expect(last, isNull);
    });

    testWidgets('いいねからアツいへ切り替え', (tester) async {
      ReactionType? last = ReactionType.like;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReactionPicker(
                  selected: last,
                  onChanged: (v) => setState(() => last = v),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('アツい'));
      await tester.pump();

      expect(last, ReactionType.fire);
    });

    testWidgets('enabled: false のときタップしても onChanged が呼ばれない', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(
              selected: null,
              enabled: false,
              onChanged: (_) => calls++,
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('いいね'), warnIfMissed: false);
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('Semantics ラベルが付与されている', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionPicker(selected: null, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.bySemanticsLabel('リアクション。いいね、見た、アツいから選べます'), findsOneWidget);
    });
  });
}
