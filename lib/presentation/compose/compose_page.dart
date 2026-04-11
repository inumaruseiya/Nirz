import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_tokens.dart';
import 'compose_notifier.dart';

/// 全画面モーダル（`fullscreenDialog`）で表示する投稿作成画面。
///
/// 詳細設計 4.4: 本文入力・任意画像・位置ぼかし後の送信。
class ComposePage extends ConsumerStatefulWidget {
  const ComposePage({super.key});

  @override
  ConsumerState<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<ComposePage> {
  static const int _maxContentLength = 2000;

  /// Storage 上限に合わせたクライアント側の目安（実装計画 1-5-3）。
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final TextEditingController _contentController = TextEditingController();

  /// 任意画像（Phase 7-1-4）。7-1-7 のアップロード用にバイト列で保持（Web でも利用可）。
  Uint8List? _pickedImageBytes;
  String _pickedImageMimeType = 'image/jpeg';

  /// 送信タップ後、本文が空または空白のみのときフィールド近傍に表示（実装計画 7-1-3）。
  bool _emptyContentSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(composeNotifierProvider.notifier).prepareLocationForCompose();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _contentValid => _contentController.text.trim().isNotEmpty;

  String? get _contentErrorText {
    if (!_emptyContentSubmitted || _contentValid) return null;
    return '本文を入力してください。空白だけの投稿はできません。';
  }

  bool _canSubmit(ComposeState composeState) {
    if (composeState is! ComposeEditing) return false;
    return composeState.locationReady;
  }

  bool _inputsLocked(ComposeState s) =>
      s is ComposeObfuscating || s is ComposeSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final composeState = ref.watch(composeNotifierProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ref.listen<ComposeState>(composeNotifierProvider, (previous, next) {
      if (next is ComposeSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.pop(true);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _inputsLocked(composeState)
              ? null
              : () => context.pop(false),
          tooltip: '閉じる',
        ),
        title: const Text('投稿を作成'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit,
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.bodyMaxLineWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          label: '投稿本文',
                          hint: '必須。最大 $_maxContentLength 文字。',
                          textField: true,
                          child: TextField(
                            controller: _contentController,
                            readOnly: _inputsLocked(composeState),
                            decoration: InputDecoration(
                              labelText: '本文',
                              hintText: '近くの出来事や気持ちを書いてください',
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                              errorText: _contentErrorText,
                            ),
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 6,
                            maxLines: 12,
                            maxLength: _maxContentLength,
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) {
                                  return Text(
                                    '$currentLength / $maxLength',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _contentErrorText != null
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    semanticsLabel:
                                        '文字数 $currentLength 文字。上限 $maxLength 文字。'
                                        '${_contentErrorText != null ? _contentErrorText! : ''}',
                                  );
                                },
                            onChanged: (_) {
                              if (_emptyContentSubmitted && _contentValid) {
                                setState(() => _emptyContentSubmitted = false);
                              } else {
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        if (_pickedImageBytes != null) ...[
                          const SizedBox(height: AppTokens.spaceUnit * 2),
                          _PickedImagePreview(
                            bytes: _pickedImageBytes!,
                            mimeType: _pickedImageMimeType,
                            onRemove: _inputsLocked(composeState)
                                ? null
                                : _clearPickedImage,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _ComposeStatusStrip(
              state: composeState,
              onDismissFailure: () =>
                  ref.read(composeNotifierProvider.notifier).dismissFailure(),
              onRetryLocation: () => ref
                  .read(composeNotifierProvider.notifier)
                  .retryPrepareLocation(),
              onOpenSettingsShortcut: _openComposeLocationSettings,
            ),
            Material(
              elevation: 2,
              shadowColor: theme.shadowColor.withValues(alpha: 0.12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit * 1.5,
                  AppTokens.spaceUnit * 2,
                  AppTokens.spaceUnit * 1.5 + bottomInset,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTokens.bodyMaxLineWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _inputsLocked(composeState)
                              ? null
                              : _onAddImagePressed,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('画像を追加'),
                        ),
                        const SizedBox(height: AppTokens.spaceUnit),
                        FilledButton.icon(
                          onPressed: _canSubmit(composeState)
                              ? _onSubmitPressed
                              : null,
                          icon: composeState is ComposeSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            composeState is ComposeSubmitting ? '送信中…' : '送信',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddImagePressed() {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('フォトライブラリ'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('カメラ'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
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
      if (bytes.length > _maxImageBytes) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('画像は5MB以下にしてください。')));
        return;
      }

      final mime = xFile.mimeType;
      setState(() {
        _pickedImageBytes = bytes;
        if (mime != null && mime.isNotEmpty) {
          _pickedImageMimeType = mime;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('画像を取得できませんでした。もう一度お試しください。')),
        );
      }
    }
  }

  void _clearPickedImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageMimeType = 'image/jpeg';
    });
  }

  Future<void> _onSubmitPressed() async {
    if (!_contentValid) {
      setState(() => _emptyContentSubmitted = true);
      return;
    }
    final notifier = ref.read(composeNotifierProvider.notifier);
    await notifier.submitPost(
      content: _contentController.text,
      imageBytes: _pickedImageBytes,
      imageContentType: _pickedImageBytes != null ? _pickedImageMimeType : null,
    );
  }

  Future<void> _openComposeLocationSettings(
    ComposeLocationSettingsShortcut shortcut,
  ) async {
    if (kIsWeb || shortcut == ComposeLocationSettingsShortcut.none) return;
    try {
      switch (shortcut) {
        case ComposeLocationSettingsShortcut.app:
          await Geolocator.openAppSettings();
        case ComposeLocationSettingsShortcut.locationServices:
          await Geolocator.openLocationSettings();
        case ComposeLocationSettingsShortcut.none:
          return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('設定を開けませんでした。')));
    }
  }
}

class _ComposeStatusStrip extends StatelessWidget {
  const _ComposeStatusStrip({
    required this.state,
    required this.onDismissFailure,
    required this.onRetryLocation,
    required this.onOpenSettingsShortcut,
  });

  final ComposeState state;
  final VoidCallback onDismissFailure;
  final Future<void> Function() onRetryLocation;
  final void Function(ComposeLocationSettingsShortcut) onOpenSettingsShortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return switch (state) {
      ComposeEditing(
        :final locationReady,
        :final locationFailureMessage,
        :final locationRetryShortcut,
      ) =>
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceUnit * 2,
            vertical: AppTokens.spaceUnit,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTokens.bodyMaxLineWidth,
              ),
              child: locationReady
                  ? Text(
                      '位置の準備ができました。本文を入力してから送信してください。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : locationFailureMessage != null
                  ? _LocationIssueCard(
                      errorMessage: locationFailureMessage,
                      settingsShortcut: locationRetryShortcut,
                      onRetry: onRetryLocation,
                      onOpenSettingsShortcut: onOpenSettingsShortcut,
                      showDismiss: false,
                    )
                  : Text(
                      '位置情報の確認が完了すると送信ボタンが有効になります。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ComposeObfuscating() => Material(
        color: colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceUnit * 2,
            vertical: AppTokens.spaceUnit * 1.5,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTokens.spaceUnit * 2),
              Expanded(
                child: Text('位置を準備しています', style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
      ComposeSubmitting() => const SizedBox.shrink(),
      ComposeSuccess() => Material(
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceUnit * 2,
            vertical: AppTokens.spaceUnit * 1.5,
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: colorScheme.primary),
              const SizedBox(width: AppTokens.spaceUnit * 2),
              Expanded(
                child: Text(
                  '投稿が完了しました',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ComposeFailure(:final message, :final settingsShortcut) => Material(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceUnit * 2,
            AppTokens.spaceUnit * 1.5,
            AppTokens.spaceUnit * 2,
            AppTokens.spaceUnit * 1.5,
          ),
          child: _LocationIssueCard(
            errorMessage: message,
            settingsShortcut: settingsShortcut,
            onRetry: onRetryLocation,
            onOpenSettingsShortcut: onOpenSettingsShortcut,
            onDismiss: onDismissFailure,
            showDismiss: true,
          ),
        ),
      ),
    };
  }
}

class _LocationIssueCard extends StatelessWidget {
  static const String _locationWhyBody =
      '近くの投稿として表示するため、おおよその位置だけをサーバーに送ります。'
      '正確な住所は保存しません。';

  const _LocationIssueCard({
    required this.errorMessage,
    required this.settingsShortcut,
    required this.onRetry,
    required this.onOpenSettingsShortcut,
    this.onDismiss,
    required this.showDismiss,
  });

  final String errorMessage;
  final ComposeLocationSettingsShortcut settingsShortcut;
  final Future<void> Function() onRetry;
  final void Function(ComposeLocationSettingsShortcut) onOpenSettingsShortcut;
  final VoidCallback? onDismiss;
  final bool showDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onError = colorScheme.onErrorContainer;
    final isBar = showDismiss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: onError),
            const SizedBox(width: AppTokens.spaceUnit * 2),
            Expanded(
              child: Text(
                errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(color: onError),
              ),
            ),
            if (showDismiss && onDismiss != null)
              TextButton(
                onPressed: onDismiss,
                child: Text('閉じる', style: TextStyle(color: onError)),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceUnit),
        Text(
          _locationWhyBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isBar
                ? onError.withValues(alpha: 0.9)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.spaceUnit * 1.5),
        Wrap(
          spacing: AppTokens.spaceUnit,
          runSpacing: AppTokens.spaceUnit,
          children: [
            FilledButton(onPressed: () => onRetry(), child: const Text('再試行')),
            if (!kIsWeb &&
                settingsShortcut != ComposeLocationSettingsShortcut.none)
              OutlinedButton(
                onPressed: () => onOpenSettingsShortcut(settingsShortcut),
                child: Text(
                  settingsShortcut ==
                          ComposeLocationSettingsShortcut.locationServices
                      ? '位置サービス設定'
                      : 'アプリの設定',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 選択画像のプレビューと削除（実装計画 7-1-4）。
class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({
    required this.bytes,
    required this.mimeType,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String mimeType;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppTokens.radiusSurface);

    return Semantics(
      label: '選択した画像',
      hint: '形式 $mimeType',
      image: true,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            if (onRemove != null)
              Padding(
                padding: const EdgeInsets.all(AppTokens.spaceUnit),
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    tooltip: '画像を削除',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        AppTokens.minTapTarget,
                        AppTokens.minTapTarget,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
