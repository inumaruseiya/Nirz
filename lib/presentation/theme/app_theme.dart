import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Material 3 ベースのアプリテーマ（ライト / ダーク）。
///
/// 詳細設計 2.2: コントラストは WCAG 2.1 AA を目安に [ColorScheme.fromSeed] で生成。
abstract final class AppTheme {
  static const Color _seed = Color(0xFF15695C);

  static ThemeData light() => _theme(brightness: Brightness.light);

  static ThemeData dark() => _theme(brightness: Brightness.dark);

  static ThemeData _theme({required Brightness brightness}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final textTheme = _textTheme(colorScheme, brightness);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ReduceMotionAwarePageTransitionsBuilder(
            const FadeUpwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: ReduceMotionAwarePageTransitionsBuilder(
            const CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: ReduceMotionAwarePageTransitionsBuilder(
            const CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.linux: ReduceMotionAwarePageTransitionsBuilder(
            const FadeUpwardsPageTransitionsBuilder(),
          ),
          TargetPlatform.windows: ReduceMotionAwarePageTransitionsBuilder(
            const FadeUpwardsPageTransitionsBuilder(),
          ),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme, Brightness brightness) {
    final base =
        ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          brightness: brightness,
        ).textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    TextStyle body(TextStyle? style) {
      final s = style ?? const TextStyle();
      return s.copyWith(height: 1.45, letterSpacing: 0.15);
    }

    TextStyle title(TextStyle? style) {
      final s = style ?? const TextStyle();
      return s.copyWith(height: 1.25, letterSpacing: 0.1);
    }

    return base.copyWith(
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      titleLarge: title(base.titleLarge),
      titleMedium: title(base.titleMedium),
      titleSmall: title(base.titleSmall),
      labelLarge: body(base.labelLarge),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }
}

/// [MediaQuery.disableAnimations] が true のときページ遷移アニメを省略（詳細設計 2.2・Phase 12-5-6）。
final class ReduceMotionAwarePageTransitionsBuilder
    extends PageTransitionsBuilder {
  const ReduceMotionAwarePageTransitionsBuilder(this._delegate);

  final PageTransitionsBuilder _delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
