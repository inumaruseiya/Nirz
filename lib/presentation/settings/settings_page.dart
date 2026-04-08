import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/user_presence_status.dart';
import '../../infrastructure/providers.dart';
import '../router/app_route_paths.dart';
import '../shared/block_user_dialog.dart';
import '../theme/app_tokens.dart';

/// 設定: 位置・プライバシー説明、OS 設定導線、ログアウト、任意ステータス（実装計画 Phase 11-1、詳細設計 4.6）。
///
/// ブロックは Phase 10-3。プロフィール編集は Phase 11-2。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _blockSubmitting = false;
  bool _signOutInProgress = false;
  bool _presenceSaving = false;

  Future<void> _openAppLocationSettings() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  Future<void> _openDeviceLocationServices() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }

  Future<void> _savePresenceStatus(UserPresenceStatus? next) async {
    if (_presenceSaving) return;
    setState(() => _presenceSaving = true);
    try {
      final result = await ref.read(profileRepositoryProvider).updateProfile(
            updatePresenceStatus: true,
            presenceStatus: next,
          );
      if (!mounted) return;
      switch (result) {
        case Ok():
          ref.invalidate(currentUserProfileProvider);
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_messageForFailure(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _presenceSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_signOutInProgress) return;
    setState(() => _signOutInProgress = true);
    try {
      final result = await ref.read(signOutUseCaseProvider)();
      if (!mounted) return;
      switch (result) {
        case Ok():
          context.go(AppRoutePaths.login);
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_messageForFailure(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _signOutInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionStateProvider);
    final signedIn = switch (sessionAsync) {
      AsyncData(:final value) => value is SessionSignedIn,
      _ => false,
    };
    final profileAsync = ref.watch(currentUserProfileProvider);

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spaceUnit * 2),
        children: [
          Text(
            '位置情報とプライバシー',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spaceUnit),
          Text(
            'このアプリは、近くの投稿を探すために端末の位置を使います。'
            'サーバーに送るのはぼかし後の位置だけで、正確な現在地は保存しません。',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spaceUnit * 1.5),
          Text(
            '位置の許可をオフにすると、フィードで近くの投稿を表示できなくなることがあります。',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.spaceUnit * 2),
          if (!kIsWeb) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.app_settings_alt_outlined),
              title: const Text('このアプリの位置情報設定'),
              subtitle: const Text('通知・位置などのアプリ権限を変更します'),
              onTap: _openAppLocationSettings,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_searching),
              title: const Text('端末の位置サービス'),
              subtitle: const Text('GPS など端末全体の位置機能のオン／オフ'),
              onTap: _openDeviceLocationServices,
            ),
            const Divider(height: AppTokens.spaceUnit * 3),
          ],
          if (signedIn) ...[
            Text(
              'マイステータス（任意）',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spaceUnit),
            profileAsync.when(
              data: (Profile? profile) {
                if (profile == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'プロフィールを読み込めませんでした。',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTokens.spaceUnit),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _presenceSaving
                              ? null
                              : () => ref.invalidate(currentUserProfileProvider),
                          child: const Text('再試行'),
                        ),
                      ),
                    ],
                  );
                }
                final current = profile.presenceStatus;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<UserPresenceStatus?>(
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        segments: const [
                          ButtonSegment<UserPresenceStatus?>(
                            value: null,
                            label: Text('なし'),
                          ),
                          ButtonSegment<UserPresenceStatus?>(
                            value: UserPresenceStatus.free,
                            label: Text('暇'),
                          ),
                          ButtonSegment<UserPresenceStatus?>(
                            value: UserPresenceStatus.working,
                            label: Text('作業中'),
                          ),
                          ButtonSegment<UserPresenceStatus?>(
                            value: UserPresenceStatus.out,
                            label: Text('外出中'),
                          ),
                        ],
                        selected: {current},
                        onSelectionChanged: (Set<UserPresenceStatus?> selected) {
                          if (_presenceSaving) return;
                          final next =
                              selected.isEmpty ? null : selected.first;
                          if (next == current) return;
                          _savePresenceStatus(next);
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceUnit * 1.5),
                    Text(
                      '近くの投稿の一覧（カード）には表示されません。設定やプロフィール周りでのみ使えます。',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_presenceSaving) ...[
                      const SizedBox(height: AppTokens.spaceUnit),
                      const LinearProgressIndicator(),
                    ],
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTokens.spaceUnit),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'プロフィールを読み込めませんでした。',
                style: textTheme.bodyLarge,
              ),
            ),
            const Divider(height: AppTokens.spaceUnit * 3),
            Semantics(
              button: true,
              label: 'ログアウト',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _signOutInProgress ? null : _signOut,
                  child: _signOutInProgress
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ログアウト'),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceUnit * 2),
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
          ],
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
