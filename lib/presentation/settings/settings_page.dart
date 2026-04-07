import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../shared/block_user_placeholder.dart';
import '../theme/app_tokens.dart';

/// Phase 11 で設定項目を実装。ブロック導線のみ Phase 10-3-1。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionStateProvider);
    final signedIn = switch (sessionAsync) {
      AsyncData(:final value) => value is SessionSignedIn,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
        children: [
          if (signedIn)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block),
              title: const Text('ユーザーをブロック（プレースホルダ）'),
              subtitle: const Text(
                'ユーザー ID を入力してブロックする流れは次の実装で有効になります。',
              ),
              onTap: () => showBlockUserPlaceholderDialog(
                context,
                subjectLabel: '指定したユーザー',
              ),
            ),
          if (signedIn)
            const Divider(height: AppTokens.spaceUnit * 3),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceUnit * 2),
              child: Text(
                '設定（Phase 11）',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
