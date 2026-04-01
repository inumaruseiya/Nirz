import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nirz/main.dart';

void main() {
  testWidgets('アプリが起動しプレースホルダが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(find.text('Nirz'), findsWidgets);
    expect(find.textContaining('Phase 0 基盤'), findsOneWidget);
  });
}
