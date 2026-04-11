import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/presentation/theme/app_theme.dart';

/// Phase 12-5-6: [MediaQuery.disableAnimations] 時にページ遷移アニメを省略（詳細設計 2.2）。
void main() {
  group('Reduce motion (disableAnimations)', () {
    const inner = Text('inner_page');

    testWidgets('ReduceMotionAwarePageTransitionsBuilder は子をそのまま返す', (
      tester,
    ) async {
      const builder = ReduceMotionAwarePageTransitionsBuilder(
        FadeUpwardsPageTransitionsBuilder(),
      );
      final route = MaterialPageRoute<void>(builder: (_) => inner);
      final animation = AlwaysStoppedAnimation<double>(1.0);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) {
                return builder.buildTransitions(
                  route,
                  context,
                  animation,
                  animation,
                  inner,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('inner_page'), findsOneWidget);
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);
    });

    testWidgets('アニメ有効時は委譲先の遷移ラッパーが付く', (tester) async {
      const builder = ReduceMotionAwarePageTransitionsBuilder(
        FadeUpwardsPageTransitionsBuilder(),
      );
      final route = MaterialPageRoute<void>(builder: (_) => inner);
      final animation = AlwaysStoppedAnimation<double>(1.0);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            disableAnimations: false,
          ),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) {
                return builder.buildTransitions(
                  route,
                  context,
                  animation,
                  animation,
                  inner,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('inner_page'), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);
    });
  });
}
