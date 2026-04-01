import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nirz/main.dart';

void main() {
  testWidgets('起動後スプラッシュ経由でログインへ（Supabase 未設定時）', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsOneWidget);
    expect(
      find.textContaining('dart-define'),
      findsOneWidget,
    );
  });
}
