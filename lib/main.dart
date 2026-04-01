import 'package:flutter/material.dart';

import 'presentation/theme/app_theme.dart';
import 'presentation/theme/app_tokens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirz',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _PlaceholderHome(),
    );
  }
}

/// Phase 0-3 までのプレースホルダ。ルーター導入後に置き換え。
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nirz'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTokens.bodyMaxLineWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Phase 0 基盤: テーマとトークンが有効です。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ルーティングは Phase 0-5 で追加予定')),
        ),
        tooltip: 'プレースホルダ',
        child: Icon(Icons.place, color: scheme.onPrimary),
      ),
    );
  }
}
