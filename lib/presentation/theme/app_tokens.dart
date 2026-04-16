import 'package:flutter/material.dart';

/// 詳細設計 2.2 に沿ったデザイントークン（論理ピクセル・Duration）。
abstract final class AppTokens {
  /// カード等の角丸（12–16 logical px の範囲）
  static const double radiusCard = 14;

  /// 補助サーフェスの角丸
  static const double radiusSurface = 12;

  /// FAB・主要 Filled ボタンなどのピルに近い角丸
  static const double radiusPill = 22;

  /// タップ領域の最小（44×44 logical px）
  static const double minTapTarget = 44;

  /// 余白の基準（8 の倍数でレイアウトすること）
  static const double spaceUnit = 8;

  /// モーションの上限目安（Reduce Motion は [MediaQuery.disableAnimations] で別途尊重）
  static const Duration motionDurationMax = Duration(milliseconds: 300);

  /// 本文の折り返し幅の目安（約 45–75 文字相当。実フォント・スケールで変動）
  static const double bodyMaxLineWidth = 560;
}
