import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../shared/block_user_dialog.dart';
import '../theme/app_tokens.dart';

/// Phase 11 で設定項目を実装。ブロックは Phase 10-3-2。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _blockSubmitting = false;

  @override
  Widget build(BuildContext context) {
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
              title: const Text('ユーザーをブロック'),
              subtitle: const Text(
                'ブロックするユーザーの UUID を入力します。',
              ),
              enabled: !_blockSubmitting,
              onTap: _blockSubmitting
                  ? null
                  : () async {
                      await showBlockUserByIdInputDialog(
                        context,
                        onConfirm: (blockedUserId) async {
                          setState(() => _blockSubmitting = true);
                          try {
                            final result =
                                await ref.read(blockUserUseCaseProvider)(
                              blockedUserId,
                            );
                            return switch (result) {
                              Ok() => null,
                              Err(:final error) => _messageForFailure(error),
                            };
                          } finally {
                            if (mounted) {
                              setState(() => _blockSubmitting = false);
                            }
                          }
                        },
                      );
                    },
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

  static String _messageForFailure(Failure f) {
    return switch (f) {
      NetworkFailure() =>
        '接続できませんでした。通信環境を確認してください。',
      AuthFailure() =>
        'セッションの有効期限が切れました。再度ログインしてください。',
      ServerFailure() =>
        'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
      ValidationFailure(:final message) => message,
      LocationFailure() => '位置情報を利用できません。',
    };
  }
}
