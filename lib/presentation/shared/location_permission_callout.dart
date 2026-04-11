import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// 位置が使えないときの説明 + OS / アプリ設定への導線（実装計画 Phase 6-3-3、詳細設計 6・FR-LOC-04）。
///
/// [onOpenSettings] では通常 `Geolocator.openAppSettings()` 等を呼ぶ。
class LocationPermissionCallout extends StatelessWidget {
  const LocationPermissionCallout({
    super.key,
    required this.onOpenSettings,
    this.title = '位置情報をオンにしてください',
    this.message = '近くの投稿を表示するには、端末の位置情報を有効にし、このアプリへの許可が必要です。設定アプリから変更できます。',
    this.openSettingsLabel = '設定を開く',
  });

  final VoidCallback onOpenSettings;
  final String title;
  final String message;
  final String openSettingsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: '$title。$message',
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceUnit * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceUnit * 1.5),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceUnit * 2),
            FilledButton(
              onPressed: onOpenSettings,
              child: Text(openSettingsLabel),
            ),
          ],
        ),
      ),
    );
  }
}
