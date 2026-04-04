import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/core/failure.dart';
import '../../domain/core/result.dart';
import '../../domain/value_objects/location_permission_state.dart';
import '../../domain/value_objects/obfuscated_location.dart';

/// 投稿作成画面の UI 状態（実装計画 Phase 7-1-2、詳細設計 5.2）。
sealed class ComposeState {
  const ComposeState();
}

/// 位置失敗時に出す設定ショートカット（Phase 7-1-6）。
enum ComposeLocationSettingsShortcut {
  none,
  app,
  locationServices,
}

/// 入力中。位置が未確定のときは [locationReady] が false で送信不可。
final class ComposeEditing extends ComposeState {
  const ComposeEditing({
    this.locationReady = false,
    this.locationRetryShortcut = ComposeLocationSettingsShortcut.none,
    this.locationFailureMessage,
  });

  final bool locationReady;

  /// 位置失敗バーを閉じたあと、再試行・設定導線用（Phase 7-1-6）。
  final ComposeLocationSettingsShortcut locationRetryShortcut;

  /// 直近の位置エラー文言（バーを閉じた後も本文付近に表示）。
  final String? locationFailureMessage;
}

/// 位置ぼかし・準備中。
final class ComposeObfuscating extends ComposeState {
  const ComposeObfuscating();
}

/// 送信中（二重送信防止）。
final class ComposeSubmitting extends ComposeState {
  const ComposeSubmitting();
}

/// 送信成功（画面を閉じる・リフレッシュは別タスク）。
final class ComposeSuccess extends ComposeState {
  const ComposeSuccess();
}

/// 失敗。[dismissFailure] 後の [ComposeEditing] では [locationReady] を引き継ぐ。
final class ComposeFailure extends ComposeState {
  const ComposeFailure(
    this.message, {
    required this.locationReady,
    this.settingsShortcut = ComposeLocationSettingsShortcut.none,
  });

  final String message;
  final bool locationReady;

  /// 送信失敗などでは [none]。
  final ComposeLocationSettingsShortcut settingsShortcut;
}

/// 投稿作成モーダル用（画面を離れたら破棄）。
final class ComposeNotifier extends AutoDisposeNotifier<ComposeState> {
  /// 非同期位置準備と競合しないよう、破棄時に無効化する。
  int _locationPrepareGeneration = 0;

  /// ぼかし済み座標（サーバ送信用）。Phase 7-1-7 の [CreatePostUseCase] で使用。
  ObfuscatedLocation? _obfuscatedLocation;

  ObfuscatedLocation? get obfuscatedLocationForSubmit => _obfuscatedLocation;

  @override
  ComposeState build() {
    ref.onDispose(() {
      _locationPrepareGeneration++;
    });
    return const ComposeEditing();
  }

  void reset() {
    _obfuscatedLocation = null;
    state = const ComposeEditing();
  }

  ComposeEditing? get _editingIfEditing => switch (state) {
        ComposeEditing s => s,
        _ => null,
      };

  /// 位置取得・ぼかし完了後に true（Phase 7-1-5 から呼ぶ）。
  void setLocationReady(bool ready) {
    final current = _editingIfEditing;
    if (current != null) {
      state = ComposeEditing(
        locationReady: ready,
        locationRetryShortcut: ComposeLocationSettingsShortcut.none,
        locationFailureMessage: null,
      );
    }
  }

  /// 画面表示時: 権限 → 現在位置 → ぼかし（実装計画 7-1-5、詳細設計 4.4）。
  Future<void> prepareLocationForCompose() async {
    if (state is ComposeObfuscating) return;
    final editing = _editingIfEditing;
    if (editing == null) return;
    if (editing.locationReady && _obfuscatedLocation != null) return;

    final token = ++_locationPrepareGeneration;
    startObfuscation();

    try {
      final permission = await ref.read(
        requestLocationPermissionUseCaseProvider,
      ).call();
      if (token != _locationPrepareGeneration) return;

      if (permission != LocationPermissionState.granted) {
        _obfuscatedLocation = null;
        final shortcut = switch (permission) {
          LocationPermissionState.denied =>
            ComposeLocationSettingsShortcut.none,
          LocationPermissionState.deniedForever =>
            ComposeLocationSettingsShortcut.app,
          LocationPermissionState.serviceDisabled =>
            ComposeLocationSettingsShortcut.locationServices,
          LocationPermissionState.granted =>
            ComposeLocationSettingsShortcut.none,
        };
        failObfuscation(
          _messageForPermission(permission),
          settingsShortcut: shortcut,
        );
        return;
      }

      final positionResult =
          await ref.read(getCurrentPositionUseCaseProvider).call();
      if (token != _locationPrepareGeneration) return;

      switch (positionResult) {
        case Ok(:final value):
          _obfuscatedLocation =
              ref.read(obfuscateLocationUseCaseProvider).call(value);
          finishObfuscation(success: true);
        case Err(:final error):
          _obfuscatedLocation = null;
          final shortcut = switch (error) {
            NetworkFailure() => ComposeLocationSettingsShortcut.none,
            LocationFailure() => ComposeLocationSettingsShortcut.app,
            _ => ComposeLocationSettingsShortcut.app,
          };
          failObfuscation(
            _messageForPositionFailure(error),
            settingsShortcut: shortcut,
          );
      }
    } catch (_) {
      if (token != _locationPrepareGeneration) return;
      _obfuscatedLocation = null;
      failObfuscation(
        '位置情報の処理に失敗しました。もう一度お試しください。',
        settingsShortcut: ComposeLocationSettingsShortcut.app,
      );
    }
  }

  /// 位置準備の再試行（Phase 7-1-6）。
  Future<void> retryPrepareLocation() async {
    if (state is ComposeFailure) {
      dismissFailure();
    }
    await prepareLocationForCompose();
  }

  void startObfuscation() {
    if (state is! ComposeEditing) return;
    state = const ComposeObfuscating();
  }

  void finishObfuscation({required bool success}) {
    if (state is! ComposeObfuscating) return;
    state = ComposeEditing(
      locationReady: success,
      locationRetryShortcut: ComposeLocationSettingsShortcut.none,
      locationFailureMessage: null,
    );
  }

  /// 位置まわりの失敗（再試行 UI は Phase 7-1-6）。
  void failObfuscation(
    String message, {
    ComposeLocationSettingsShortcut settingsShortcut =
        ComposeLocationSettingsShortcut.app,
  }) {
    if (state is! ComposeObfuscating) return;
    state = ComposeFailure(
      message,
      locationReady: false,
      settingsShortcut: settingsShortcut,
    );
  }

  void startSubmit() {
    final current = _editingIfEditing;
    if (current == null || !current.locationReady) return;
    state = const ComposeSubmitting();
  }

  void markSubmitSuccess() {
    if (state is! ComposeSubmitting) return;
    state = const ComposeSuccess();
  }

  void markSubmitFailure(String message) {
    if (state is! ComposeSubmitting) return;
    state = ComposeFailure(
      message,
      locationReady: true,
      settingsShortcut: ComposeLocationSettingsShortcut.none,
    );
  }

  void dismissFailure() {
    if (state case ComposeFailure(
          :final message,
          :final locationReady,
          :final settingsShortcut,
        )) {
      state = ComposeEditing(
        locationReady: locationReady,
        locationRetryShortcut: !locationReady
            ? settingsShortcut
            : ComposeLocationSettingsShortcut.none,
        locationFailureMessage: !locationReady ? message : null,
      );
    }
  }

  /// 成功後に同画面で続けて書く場合など（主にテスト・将来用）。
  void clearSuccessToEditing() {
    if (state is ComposeSuccess) {
      _obfuscatedLocation = null;
      state = const ComposeEditing(locationReady: false);
    }
  }

  static String _messageForPermission(LocationPermissionState permission) {
    return switch (permission) {
      LocationPermissionState.denied =>
        '位置情報の利用が許可されていません。設定から許可してください。',
      LocationPermissionState.deniedForever =>
        '位置情報が「許可しない」になっています。設定アプリから許可を変更してください。',
      LocationPermissionState.serviceDisabled =>
        '端末の位置情報サービスがオフです。設定でオンにしてください。',
      LocationPermissionState.granted => '',
    };
  }

  static String _messageForPositionFailure(Failure failure) {
    return switch (failure) {
      NetworkFailure() =>
        '位置情報の取得がタイムアウトしました。通信環境を確認してから再度お試しください。',
      LocationFailure() => '現在地を取得できませんでした。もう一度お試しください。',
      ValidationFailure(:final message) => message,
      AuthFailure() => 'セッションの有効期限が切れました。再度ログインしてください。',
      ServerFailure() => 'サーバーで問題が発生しました。しばらくしてから再度お試しください。',
    };
  }
}

final composeNotifierProvider =
    NotifierProvider.autoDispose<ComposeNotifier, ComposeState>(
  ComposeNotifier.new,
);
