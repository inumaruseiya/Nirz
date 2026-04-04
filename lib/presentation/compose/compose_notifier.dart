import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 投稿作成画面の UI 状態（実装計画 Phase 7-1-2、詳細設計 5.2）。
sealed class ComposeState {
  const ComposeState();
}

/// 入力中。位置が未確定のときは [locationReady] が false で送信不可。
final class ComposeEditing extends ComposeState {
  const ComposeEditing({this.locationReady = false});

  final bool locationReady;
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
  const ComposeFailure(this.message, {required this.locationReady});

  final String message;
  final bool locationReady;
}

/// 投稿作成モーダル用（画面を離れたら破棄）。
final class ComposeNotifier extends AutoDisposeNotifier<ComposeState> {
  @override
  ComposeState build() => const ComposeEditing();

  void reset() => state = const ComposeEditing();

  ComposeEditing? get _editingIfEditing => switch (state) {
        ComposeEditing s => s,
        _ => null,
      };

  /// 位置取得・ぼかし完了後に true（Phase 7-1-5 から呼ぶ）。
  void setLocationReady(bool ready) {
    final current = _editingIfEditing;
    if (current != null) {
      state = ComposeEditing(locationReady: ready);
    }
  }

  void startObfuscation() {
    if (state is! ComposeEditing) return;
    state = const ComposeObfuscating();
  }

  void finishObfuscation({required bool success}) {
    if (state is! ComposeObfuscating) return;
    state = ComposeEditing(locationReady: success);
  }

  /// 位置まわりの失敗（再試行 UI は Phase 7-1-6）。
  void failObfuscation(String message) {
    if (state is! ComposeObfuscating) return;
    state = ComposeFailure(message, locationReady: false);
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
    state = ComposeFailure(message, locationReady: true);
  }

  void dismissFailure() {
    if (state case ComposeFailure(:final locationReady)) {
      state = ComposeEditing(locationReady: locationReady);
    }
  }

  /// 成功後に同画面で続けて書く場合など（主にテスト・将来用）。
  void clearSuccessToEditing() {
    if (state is ComposeSuccess) {
      state = const ComposeEditing(locationReady: false);
    }
  }
}

final composeNotifierProvider =
    NotifierProvider.autoDispose<ComposeNotifier, ComposeState>(
  ComposeNotifier.new,
);
