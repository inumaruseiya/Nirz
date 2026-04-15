import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Material 3 ベースのアプリテーマ（ライト / ダーク）。
///
/// 詳細設計 2.2: コントラストは WCAG 2.1 AA を目安に [ColorScheme.fromSeed] で生成し、
/// 位置情報共有アプリ Bump を参考に暖色アクセントとニュートラル面へ調整する。
abstract final class AppTheme {
  /// コーラル系アクセント（近距離・親しみやすいトーン）
  static const Color _bumpSeed = Color(0xFFFF5A4D);

  static ThemeData light() => _theme(brightness: Brightness.light);

  static ThemeData dark() => _theme(brightness: Brightness.dark);

  static ColorScheme _colorScheme(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
      seedColor: _bumpSeed,
      brightness: brightness,
    );
    if (brightness == Brightness.light) {
      scheme = scheme.copyWith(
        surfaceTint: Colors.transparent,
        surface: const Color(0xFFFFF7F5),
        surfaceContainerLowest: const Color(0xFFFFFAF8),
        surfaceContainerLow: const Color(0xFFFFF3F0),
        surfaceContainer: const Color(0xFFF5EDEA),
        surfaceContainerHigh: const Color(0xFFEEE6E3),
        surfaceContainerHighest: const Color(0xFFE8E0DD),
      );
    } else {
      scheme = scheme.copyWith(surfaceTint: Colors.transparent);
    }
    return scheme;
  }

  static ThemeData _theme({required Brightness brightness}) {
    final colorScheme = _colorScheme(brightness);
    final textTheme = _textTheme(colorScheme, brightness);

    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
    );
    final surfaceShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: colorScheme.primary.withValues(alpha: 0.10),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surfaceContainerLowest,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: textTheme.bodyLarge,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppTokens.spaceUnit * 2,
          0,
          AppTokens.spaceUnit * 2,
          AppTokens.spaceUnit * 2,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit * 1.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusCard),
          ),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 3,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: pillShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: pillShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: surfaceShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: surfaceShape,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSurface)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit * 1.5,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
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
      titleLarge: title(base.titleLarge).copyWith(fontWeight: FontWeight.w700),
      titleMedium: title(base.titleMedium).copyWith(fontWeight: FontWeight.w600),
      titleSmall: title(base.titleSmall).copyWith(fontWeight: FontWeight.w600),
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
