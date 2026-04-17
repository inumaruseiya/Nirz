import 'package:flutter/material.dart';

/// shadcn/ui Design System に準拠したデザイントークン。
/// border-radius は --radius: 0.5rem (8px) をベースに統一。
abstract final class AppTokens {
  /// カード・ダイアログ等の角丸（shadcn/ui --radius = 0.5rem）
  static const double radiusCard = 8;

  /// インプット・補助サーフェスの角丸
  static const double radiusSurface = 8;

  /// FAB のみに使う大きめ角丸
  static const double radiusPill = 9999;

  /// タップ領域の最小（44×44 logical px）
  static const double minTapTarget = 44;

  /// 余白の基準（8 の倍数でレイアウトすること）
  static const double spaceUnit = 8;

  /// モーションの上限目安
  static const Duration motionDurationMax = Duration(milliseconds: 300);

  /// 本文の折り返し幅の目安
  static const double bodyMaxLineWidth = 560;

  // ── shadcn/ui カラーパレット (Slate) ────────────────────────────
  /// Light: background / card
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);
}
