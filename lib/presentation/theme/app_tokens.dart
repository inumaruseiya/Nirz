import 'package:flutter/material.dart';

/// 詳細設計 2.2 に沿ったデザイントークン（論理ピクセル・Duration）。
///
/// HIG に近い画面端・セクション間隔もここで統一（Material 3 のまま iOS 風レイアウト用）。
abstract final class AppTokens {
  /// 画面左右の標準インセット（HIG の約 16pt に相当）
  static const double screenHorizontalInset = 16;

  /// 画面上下でコンテンツを端から離すときの目安
  static const double screenVerticalInset = 16;

  /// リスト行・設定タイル内の水平余白（インセットグループ風）
  static const double listContentPaddingHorizontal = 16;

  /// カード等の角丸（12–16 logical px の範囲）
  static const double radiusCard = 14;

  /// 補助サーフェスの角丸
  static const double radiusSurface = 12;

  /// タップ領域の最小（44×44 logical px）
  static const double minTapTarget = 44;

  /// 余白の基準（8 の倍数でレイアウトすること）
  static const double spaceUnit = 8;

  /// セクション見出しと本文の間など（`spaceUnit` の倍数）
  static const double sectionSpacing = spaceUnit * 2;

  /// モーションの上限目安（Reduce Motion は [MediaQuery.disableAnimations] で別途尊重）
  static const Duration motionDurationMax = Duration(milliseconds: 300);

  /// 本文の折り返し幅の目安（約 45–75 文字相当。実フォント・スケールで変動）
  static const double bodyMaxLineWidth = 560;
}
