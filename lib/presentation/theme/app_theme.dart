import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// shadcn/ui Design System (Slate) に準拠した Material 3 テーマ。
///
/// Light: 白背景 + ダークネイビー primary、Slate ボーダー。
/// Dark : Slate-950 背景 + 白 primary。
abstract final class AppTheme {
  /// shadcn/ui default: primary = slate-900 に近い slate seed
  static const Color _slateSeed = Color(0xFF1E293B);

  static ThemeData light() => _theme(brightness: Brightness.light);

  static ThemeData dark() => _theme(brightness: Brightness.dark);

  // ── Color Scheme ──────────────────────────────────────────────────

  static ColorScheme _colorScheme(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
      seedColor: _slateSeed,
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      scheme = scheme.copyWith(
        surfaceTint: Colors.transparent,
        // shadcn/ui: background = white, card = white
        surface: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: AppTokens.slate50,
        surfaceContainer: AppTokens.slate100,
        surfaceContainerHigh: AppTokens.slate200,
        surfaceContainerHighest: AppTokens.slate300,
        // shadcn/ui: border = slate-200, muted-foreground = slate-500
        outline: AppTokens.slate300,
        outlineVariant: AppTokens.slate200,
        onSurfaceVariant: AppTokens.slate500,
      );
    } else {
      // shadcn/ui dark: background = slate-950, card = slate-950
      scheme = scheme.copyWith(
        surfaceTint: Colors.transparent,
        surface: AppTokens.slate950,
        surfaceContainerLowest: AppTokens.slate950,
        surfaceContainerLow: AppTokens.slate900,
        surfaceContainer: AppTokens.slate800,
        surfaceContainerHigh: AppTokens.slate700,
        surfaceContainerHighest: AppTokens.slate600,
        // shadcn/ui dark border = slate-800
        outline: AppTokens.slate700,
        outlineVariant: AppTokens.slate800,
        onSurfaceVariant: AppTokens.slate400,
      );
    }
    return scheme;
  }

  // ── Theme ─────────────────────────────────────────────────────────

  static ThemeData _theme({required Brightness brightness}) {
    final colorScheme = _colorScheme(brightness);
    final textTheme = _textTheme(colorScheme, brightness);

    // shadcn/ui: all buttons/inputs use --radius (8px), not pill
    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
    );
    final cardBorder = BorderSide(
      color: colorScheme.outlineVariant,
      width: 1,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.04),

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        shadowColor: colorScheme.outlineVariant,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────
      // shadcn/ui: flat white card, 1px border, no shadow
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: cardBorder,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ── Dialog ────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: cardBorder,
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

      // ── Divider ───────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit * 1.5,
        ),
      ),

      // ── BottomSheet ───────────────────────────────────────────────
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

      // ── ListTile ──────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 2,
          vertical: AppTokens.spaceUnit,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        focusElevation: 1,
        hoverElevation: 1,
        highlightElevation: 1,
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

      // ── Buttons ───────────────────────────────────────────────────
      // shadcn/ui: all buttons use --radius (8px)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: btnShape,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: btnShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: btnShape,
          side: cardBorder,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTapTarget,
            AppTokens.minTapTarget,
          ),
          shape: btnShape,
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

      // ── Input ─────────────────────────────────────────────────────
      // shadcn/ui: border input style, bg = surface, border = slate-200
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSurface),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceUnit * 1.5,
          vertical: AppTokens.spaceUnit * 1.5,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      // ── Progress ──────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHigh,
        circularTrackColor: colorScheme.surfaceContainerHigh,
      ),

      // ── Page Transitions ──────────────────────────────────────────
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

  // ── Text Theme ────────────────────────────────────────────────────

  static TextTheme _textTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    ).textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    TextStyle body(TextStyle? s) =>
        (s ?? const TextStyle()).copyWith(height: 1.5, letterSpacing: 0.1);

    TextStyle title(TextStyle? s) =>
        (s ?? const TextStyle()).copyWith(height: 1.3, letterSpacing: 0);

    return base.copyWith(
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      titleLarge: title(base.titleLarge).copyWith(fontWeight: FontWeight.w700),
      titleMedium:
          title(base.titleMedium).copyWith(fontWeight: FontWeight.w600),
      titleSmall: title(base.titleSmall).copyWith(fontWeight: FontWeight.w600),
      labelLarge: body(base.labelLarge).copyWith(fontWeight: FontWeight.w500),
      labelMedium: body(base.labelMedium),
      labelSmall: body(base.labelSmall),
    );
  }
}

/// [MediaQuery.disableAnimations] が true のときページ遷移アニメを省略。
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
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _delegate.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
