import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../motion/shared_axis.dart';
import 'game_colors.dart';

abstract final class AppFonts {
  static const display = 'Bricolage Grotesque';
  static const body = 'Nunito';

  /// Handwriting, used only on the paper slips.
  static const hand = 'Kalam';

  /// Arabic has no glyphs in the faces above; these fill in, in either language.
  static const arabic = ['Baloo Bhaijaan 2'];
  static const arabicHand = ['Aref Ruqaa'];
}

abstract final class AppTheme {
  static ThemeData light() => _build(_light, GameColors.light);
  static ThemeData dark() => _build(_dark, GameColors.dark);

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4A3FCF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3E0FF),
    onPrimaryContainer: Color(0xFF221A7A),
    secondary: Color(0xFF625E7A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE9E7F5),
    onSecondaryContainer: Color(0xFF1D1A33),
    tertiary: Color(0xFFD9480F),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFF2F1F8),
    onSurface: Color(0xFF1D1A33),
    onSurfaceVariant: Color(0xFF625E7A),
    outline: Color(0xFF8E89A8),
    outlineVariant: Color(0xFFD8D5E8),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF7F6FB),
    surfaceContainerHigh: Color(0xFFEDEBF7),
    surfaceContainerHighest: Color(0xFFE9E7F5),
    inverseSurface: Color(0xFF1D1A33),
    onInverseSurface: Color(0xFFF2F1F8),
    inversePrimary: Color(0xFFB3AAFF),
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB3AAFF),
    onPrimary: Color(0xFF1B1560),
    primaryContainer: Color(0xFF342C86),
    onPrimaryContainer: Color(0xFFE3E0FF),
    secondary: Color(0xFFA29DBD),
    onSecondary: Color(0xFF14121F),
    secondaryContainer: Color(0xFF2A2640),
    onSecondaryContainer: Color(0xFFECEAF6),
    tertiary: Color(0xFFFF8A50),
    onTertiary: Color(0xFF14121F),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF14121F),
    onSurface: Color(0xFFECEAF6),
    onSurfaceVariant: Color(0xFFA29DBD),
    outline: Color(0xFF6E6989),
    outlineVariant: Color(0xFF37324F),
    surfaceContainerLowest: Color(0xFF1E1B2C),
    surfaceContainerLow: Color(0xFF1E1B2C),
    surfaceContainer: Color(0xFF221F32),
    surfaceContainerHigh: Color(0xFF26233A),
    surfaceContainerHighest: Color(0xFF2A2640),
    inverseSurface: Color(0xFFECEAF6),
    onInverseSurface: Color(0xFF14121F),
    inversePrimary: Color(0xFF4A3FCF),
  );

  static ThemeData _build(ColorScheme scheme, GameColors game) {
    final base = ThemeData(colorScheme: scheme, fontFamily: AppFonts.body, fontFamilyFallback: AppFonts.arabic);
    final text = base.textTheme;
    TextStyle? display(TextStyle? style, FontWeight weight, [double spacing = 0]) =>
        style?.copyWith(fontFamily: AppFonts.display, fontWeight: weight, letterSpacing: spacing, height: 1.05);

    final textTheme = text.copyWith(
      displayMedium: display(text.displayMedium, FontWeight.w800, -1.2),
      displaySmall: display(text.displaySmall, FontWeight.w800, -0.8),
      headlineLarge: display(text.headlineLarge, FontWeight.w800, -0.6),
      headlineMedium: display(text.headlineMedium, FontWeight.w800, -0.4),
      headlineSmall: display(text.headlineSmall, FontWeight.w700),
      titleLarge: display(text.titleLarge, FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      labelSmall: text.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.1),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
    );

    const fieldRadius = BorderRadius.all(Radius.circular(14));
    const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [game],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
          TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
          // Keep the native swipe-back gesture on Apple platforms.
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Theme text styles get their sizes only when MaterialApp localizes them,
        // so the app bar title needs an explicit one.
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface, fontSize: 20),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 44), textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
      dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerLowest),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    );
  }
}
