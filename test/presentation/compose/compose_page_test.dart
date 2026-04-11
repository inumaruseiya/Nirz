import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirz/presentation/compose/compose_notifier.dart';
import 'package:nirz/presentation/compose/compose_page.dart';

/// 状態固定・副作用なし（Widget テスト用）。
class _TestComposeNotifier extends ComposeNotifier {
  _TestComposeNotifier(this._fixed);

  final ComposeState _fixed;

  @override
  ComposeState build() => _fixed;

  @override
  Future<void> prepareLocationForCompose() async {}

  @override
  Future<void> submitPost({
    required String content,
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    submitted.add((
      content: content,
      imageBytes: imageBytes,
      imageContentType: imageContentType,
    ));
    state = const ComposeSuccess();
  }

  final List<
    ({String content, Uint8List? imageBytes, String? imageContentType})
  >
  submitted = [];
}

/// [ComposePage] の `context.pop` 用に、下にスタックを積む。
class _ComposeTestShell extends StatefulWidget {
  const _ComposeTestShell();

  @override
  State<_ComposeTestShell> createState() => _ComposeTestShellState();
}

class _ComposeTestShellState extends State<_ComposeTestShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.push('/compose');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('compose_test_shell'));
  }
}

Future<void> _pumpCompose(
  WidgetTester tester, {
  required ComposeState composeState,
  _TestComposeNotifier? notifier,
}) async {
  final n = notifier ?? _TestComposeNotifier(composeState);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [composeNotifierProvider.overrideWith(() => n)],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const _ComposeTestShell(),
            ),
            GoRoute(
              path: '/compose',
              builder: (context, state) => const ComposePage(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  // [ComposeObfuscating] 等では [CircularProgressIndicator] が常時アニメするため
  // pumpAndSettle は使わない。
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (find.text('投稿を作成').evaluate().isNotEmpty) break;
  }
  expect(find.text('投稿を作成'), findsOneWidget);
}

FilledButton _sendButton(WidgetTester tester) {
  final sendIcon = find.byIcon(Icons.send_outlined);
  expect(sendIcon, findsOneWidget);
  return tester.widget<FilledButton>(
    find.ancestor(of: sendIcon, matching: find.byType(FilledButton)),
  );
}

void main() {
  group('ComposePage', () {
    testWidgets('位置未準備: 送信ボタンが無効', (tester) async {
      await _pumpCompose(
        tester,
        composeState: const ComposeEditing(locationReady: false),
      );

      expect(_sendButton(tester).onPressed, isNull);
      expect(find.text('位置情報の確認が完了すると送信ボタンが有効になります。'), findsOneWidget);
    });

    testWidgets('位置準備済み・本文なし: 送信タップでバリデーション文言', (tester) async {
      await _pumpCompose(
        tester,
        composeState: const ComposeEditing(locationReady: true),
      );

      expect(_sendButton(tester).onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();

      expect(find.text('本文を入力してください。空白だけの投稿はできません。'), findsOneWidget);
    });

    testWidgets('位置準備済み・空白のみ: 送信タップでバリデーション文言', (tester) async {
      await _pumpCompose(
        tester,
        composeState: const ComposeEditing(locationReady: true),
      );

      await tester.enterText(find.byType(TextField), '   \n  ');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();

      expect(find.text('本文を入力してください。空白だけの投稿はできません。'), findsOneWidget);
    });

    testWidgets('位置準備済み・本文あり: 送信で submitPost が呼ばれて閉じる', (tester) async {
      final notifier = _TestComposeNotifier(
        const ComposeEditing(locationReady: true),
      );
      await _pumpCompose(
        tester,
        composeState: notifier.build(),
        notifier: notifier,
      );

      await tester.enterText(find.byType(TextField), 'こんにちは');
      await tester.pump();

      expect(_sendButton(tester).onPressed, isNotNull);
      expect(notifier.submitted, isEmpty);

      await tester.tap(find.byIcon(Icons.send_outlined));
      await tester.pump();
      await tester.pump();

      expect(notifier.submitted, hasLength(1));
      expect(notifier.submitted.single.content, 'こんにちは');
      expect(notifier.submitted.single.imageBytes, isNull);
      expect(notifier.submitted.single.imageContentType, isNull);
    });

    testWidgets('ComposeObfuscating: テキストが読み取り専用・送信無効', (tester) async {
      await _pumpCompose(tester, composeState: const ComposeObfuscating());

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(_sendButton(tester).onPressed, isNull);
      expect(find.text('位置を準備しています'), findsOneWidget);
    });

    testWidgets('ComposeSubmitting: 送信中ラベルとインジケータ', (tester) async {
      await _pumpCompose(tester, composeState: const ComposeSubmitting());

      expect(find.text('送信中…'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsWidgets,
      );
    });
  });
}
