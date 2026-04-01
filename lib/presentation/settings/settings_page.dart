import 'package:flutter/material.dart';

/// Phase 11 で設定項目を実装。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Center(
        child: Text(
          '設定（Phase 11）',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
