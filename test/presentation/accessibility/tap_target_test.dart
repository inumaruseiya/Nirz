import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/domain/value_objects/reaction_type.dart';
import 'package:nirz/presentation/shared/reaction_picker.dart';
import 'package:nirz/presentation/theme/app_theme.dart';
import 'package:nirz/presentation/theme/app_tokens.dart';

/// Phase 12-5-1: 主要インタラクティブが [AppTokens.minTapTarget] 以上のヒット領域を持つこと。
void main() {
  group('Tap targets (44×44 logical px)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    Future<void> pumpWithTheme(WidgetTester tester, Widget child) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    void expectAtLeastMinTapTarget(RenderBox box, {String? label}) {
      expect(
        box.size.width,
        greaterThanOrEqualTo(AppTokens.minTapTarget),
        reason: label,
      );
      expect(
        box.size.height,
        greaterThanOrEqualTo(AppTokens.minTapTarget),
        reason: label,
      );
    }

    testWidgets('Theme IconButton', (tester) async {
      await pumpWithTheme(
        tester,
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
      );
      final box = tester.renderObject<RenderBox>(find.byType(IconButton));
      expectAtLeastMinTapTarget(box, label: 'IconButton');
    });

    testWidgets('Theme FilledButton', (tester) async {
      await pumpWithTheme(
        tester,
        FilledButton(onPressed: () {}, child: const Text('送信')),
      );
      final box = tester.renderObject<RenderBox>(find.byType(FilledButton));
      expectAtLeastMinTapTarget(box, label: 'FilledButton');
    });

    testWidgets('Theme OutlinedButton', (tester) async {
      await pumpWithTheme(
        tester,
        OutlinedButton(onPressed: () {}, child: const Text('画像を追加')),
      );
      final box = tester.renderObject<RenderBox>(find.byType(OutlinedButton));
      expectAtLeastMinTapTarget(box, label: 'OutlinedButton');
    });

    testWidgets('Theme TextButton', (tester) async {
      await pumpWithTheme(
        tester,
        TextButton(onPressed: () {}, child: const Text('閉じる')),
      );
      final box = tester.renderObject<RenderBox>(find.byType(TextButton));
      expectAtLeastMinTapTarget(box, label: 'TextButton');
    });

    testWidgets('ReactionPicker SegmentedButton', (tester) async {
      await pumpWithTheme(
        tester,
        ReactionPicker(selected: null, onChanged: (_) {}),
      );
      final box = tester.renderObject<RenderBox>(
        find.byType(SegmentedButton<ReactionType>),
      );
      expectAtLeastMinTapTarget(box, label: 'SegmentedButton<ReactionType>');
    });
  });
}
