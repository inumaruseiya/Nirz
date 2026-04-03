import 'package:flutter/material.dart';

/// 一覧系画面の **loading / ready / empty / error** 表示切替（実装計画 Phase 6-3-1、詳細設計 6）。
///
/// 表示中の相だけ [WidgetBuilder] が呼ばれる（非表示の相はビルドしない）。
/// フィードのように「ready はリスト用スライバで別建て」する場合は [phase] を
/// [AsyncViewPhase.ready] にせず、[ready] にはプレースホルダを返す。
class AsyncStateSwitcher extends StatelessWidget {
  const AsyncStateSwitcher({
    super.key,
    required this.phase,
    required this.loading,
    required this.ready,
    required this.empty,
    required this.error,
  });

  final AsyncViewPhase phase;
  final WidgetBuilder loading;
  final WidgetBuilder ready;
  final WidgetBuilder empty;
  final WidgetBuilder error;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      AsyncViewPhase.loading => loading(context),
      AsyncViewPhase.ready => ready(context),
      AsyncViewPhase.empty => empty(context),
      AsyncViewPhase.error => error(context),
    };
  }
}

enum AsyncViewPhase {
  loading,
  ready,
  empty,
  error,
}
