import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/user_presence_status.dart';
import '../../infrastructure/providers.dart';
import '../auth/auth_field_validators.dart';
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
  static const int _maxAvatarBytes = 5 * 1024 * 1024;

  final _nicknameFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _blockSubmitting = false;
  bool _signOutInProgress = false;
  bool _presenceSaving = false;
  bool _nicknameDirty = false;
  bool _displayNameSaving = false;
  bool _avatarSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openAppLocationSettings() async {
    if (kIsWeb) return;
    await Geolocator.openAppSettings();
  }

  Future<void> _openDeviceLocationServices() async {
    if (kIsWeb) return;
    await Geolocator.openLocationSettings();
  }

  Future<void> _saveDisplayName(Profile current) async {
    if (_displayNameSaving) return;
    if (!(_nicknameFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final name = _nameController.text.trim();
    final before = (current.displayName ?? '').trim();
    if (name == before) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('変更がありません')),
      );
      return;
    }

    setState(() => _displayNameSaving = true);
    try {
      final result = await ref.read(profileRepositoryProvider).updateProfile(
            displayName: name,
          );
      if (!mounted) return;
      switch (result) {
        case Ok():
          setState(() => _nicknameDirty = false);
          ref.invalidate(currentUserProfileProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ニックネームを保存しました')),
          );
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_messageForFailure(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _displayNameSaving = false);
      }
    }
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    if (_avatarSaving) return;
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (xFile == null || !mounted) return;

      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxAvatarBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像は5MB以下にしてください。')),
        );
        return;
      }

      var mime = xFile.mimeType?.trim();
      if (mime == null || mime.isEmpty) {
        mime = 'image/jpeg';
      }

      await _uploadAndSaveAvatar(bytes, mime);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を取得できませんでした。もう一度お試しください。'),
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSaveAvatar(
    Uint8List bytes,
    String contentType,
  ) async {
    if (_avatarSaving) return;
    setState(() => _avatarSaving = true);
    try {
      final upload = await ref.read(storageRepositoryProvider).uploadPostImage(
            bytes,
            contentType,
          );
      if (!mounted) return;
      switch (upload) {
        case Ok(:final value):
          final result = await ref.read(profileRepositoryProvider).updateProfile(
                avatarUrl: value.toString(),
                updateAvatarUrl: true,
              );
          if (!mounted) return;
          switch (result) {
            case Ok():
              ref.invalidate(currentUserProfileProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロフィール画像を更新しました')),
              );
            case Err(:final error):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_messageForFailure(error))),
              );
          }
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_messageForFailure(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _avatarSaving = false);
      }
    }
  }

  Future<void> _removeAvatar(Profile current) async {
    if (_avatarSaving) return;
    final url = current.avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除する画像がありません')),
      );
      return;
    }

    setState(() => _avatarSaving = true);
    try {
      final result = await ref.read(profileRepositoryProvider).updateProfile(
            updateAvatarUrl: true,
            avatarUrl: null,
          );
      if (!mounted) return;
      switch (result) {
        case Ok():
          ref.invalidate(currentUserProfileProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('プロフィール画像を削除しました')),
          );
        case Err(:final error):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_messageForFailure(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _avatarSaving = false);
      }
    }
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

    if (signedIn) {
      final profile = switch (profileAsync) {
        AsyncData(:final value) => value,
        _ => null,
      };
      if (profile != null && !_nicknameDirty) {
        final nextName = profile.displayName?.trim() ?? '';
        if (_nameController.text != nextName) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _nicknameDirty) return;
            if (_nameController.text != nextName) {
              _nameController.text = nextName;
            }
          });
        }
      }
    }

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
              'ニックネーム',
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
                          onPressed: _displayNameSaving
                              ? null
                              : () => ref.invalidate(currentUserProfileProvider),
                          child: const Text('再試行'),
                        ),
                      ),
                    ],
                  );
                }
                final avatarUrl = profile.avatarUrl?.trim();
                final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Form(
                      key: _nicknameFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.nickname],
                            decoration: const InputDecoration(
                              labelText: 'ニックネーム',
                              hintText: '表示名（フィードなどに表示）',
                            ),
                            maxLength: AuthFieldValidators.nicknameMaxLength,
                            validator: AuthFieldValidators.nickname,
                            onChanged: (_) {
                              if (!_nicknameDirty) {
                                setState(() => _nicknameDirty = true);
                              }
                            },
                          ),
                          const SizedBox(height: AppTokens.spaceUnit),
                          FilledButton(
                            onPressed: _displayNameSaving || _avatarSaving
                                ? null
                                : () => _saveDisplayName(profile),
                            child: _displayNameSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('ニックネームを保存'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceUnit * 2),
                    Text(
                      'プロフィール画像（任意）',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.spaceUnit),
                    Text(
                      '投稿画像と同じストレージに保存します（最大5MB）。',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceUnit * 1.5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: hasAvatar
                                ? Semantics(
                                    image: true,
                                    label: '現在のプロフィール画像',
                                    child: CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          ColoredBox(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : Semantics(
                                    label: 'プロフィール画像は未設定です',
                                    child: ColoredBox(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceUnit * 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _avatarSaving
                                    ? null
                                    : () => _pickAvatarImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('ギャラリーから選ぶ'),
                              ),
                              if (!kIsWeb) ...[
                                const SizedBox(height: AppTokens.spaceUnit),
                                OutlinedButton.icon(
                                  onPressed: _avatarSaving
                                      ? null
                                      : () =>
                                          _pickAvatarImage(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: const Text('カメラで撮る'),
                                ),
                              ],
                              if (hasAvatar) ...[
                                const SizedBox(height: AppTokens.spaceUnit),
                                TextButton(
                                  onPressed: _avatarSaving
                                      ? null
                                      : () => _removeAvatar(profile),
                                  child: const Text('画像を削除'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_avatarSaving) ...[
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
              error: (error, stackTrace) => Text(
                'プロフィールを読み込めませんでした。',
                style: textTheme.bodyLarge,
              ),
            ),
            const Divider(height: AppTokens.spaceUnit * 3),
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
              error: (error, stackTrace) => Text(
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
