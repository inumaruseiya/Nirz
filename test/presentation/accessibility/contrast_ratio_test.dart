import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirz/presentation/theme/app_theme.dart';

/// WCAG 2.1 の相対輝度（sRGB 0–1）。アルファは無視し不透明として扱う。
double _linearChannel(double srgb) {
  final c = srgb.clamp(0.0, 1.0);
  if (c <= 0.03928) {
    return c / 12.92;
  }
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _linearChannel(color.r);
  final g = _linearChannel(color.g);
  final b = _linearChannel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG 2.1 のコントラスト比（大きい方の輝度を分子側に）。
double contrastRatio(Color foreground, Color background) {
  final lFg = _relativeLuminance(foreground);
  final lBg = _relativeLuminance(background);
  final lighter = math.max(lFg, lBg);
  final darker = math.min(lFg, lBg);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Phase 12-5-4: [AppTheme] の [ColorScheme] が本文・主要 UI 色で WCAG 2.1 AA（4.5:1）を満たすこと。
///
/// 詳細設計 2.2・実装計画 12-5-4。シード生成色の回帰防止用。
void main() {
  const aaNormalText = 4.5;

  void expectAtLeastAa(Color fg, Color bg, String pairLabel) {
    final ratio = contrastRatio(fg, bg);
    expect(
      ratio,
      greaterThanOrEqualTo(aaNormalText),
      reason: '$pairLabel: contrast $ratio (need >= $aaNormalText)',
    );
  }

  group('ColorScheme contrast (WCAG 2.1 AA 4.5:1)', () {
    test('AppTheme.light primary text and controls', () {
      final scheme = AppTheme.light().colorScheme;
      expectAtLeastAa(scheme.onSurface, scheme.surface, 'onSurface / surface');
      expectAtLeastAa(
        scheme.onSurfaceVariant,
        scheme.surface,
        'onSurfaceVariant / surface',
      );
      expectAtLeastAa(scheme.onPrimary, scheme.primary, 'onPrimary / primary');
      expectAtLeastAa(scheme.onError, scheme.error, 'onError / error');
      expectAtLeastAa(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        'onPrimaryContainer / primaryContainer',
      );
      expectAtLeastAa(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        'onSecondaryContainer / secondaryContainer',
      );
      expectAtLeastAa(
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
        'onTertiaryContainer / tertiaryContainer',
      );
      expectAtLeastAa(
        scheme.onErrorContainer,
        scheme.errorContainer,
        'onErrorContainer / errorContainer',
      );
    });

    test('AppTheme.dark primary text and controls', () {
      final scheme = AppTheme.dark().colorScheme;
      expectAtLeastAa(scheme.onSurface, scheme.surface, 'onSurface / surface');
      expectAtLeastAa(
        scheme.onSurfaceVariant,
        scheme.surface,
        'onSurfaceVariant / surface',
      );
      expectAtLeastAa(scheme.onPrimary, scheme.primary, 'onPrimary / primary');
      expectAtLeastAa(scheme.onError, scheme.error, 'onError / error');
      expectAtLeastAa(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        'onPrimaryContainer / primaryContainer',
      );
      expectAtLeastAa(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        'onSecondaryContainer / secondaryContainer',
      );
      expectAtLeastAa(
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
        'onTertiaryContainer / tertiaryContainer',
      );
      expectAtLeastAa(
        scheme.onErrorContainer,
        scheme.errorContainer,
        'onErrorContainer / errorContainer',
      );
    });
  });
}
