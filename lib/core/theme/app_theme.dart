import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central app theme.
///
/// Exposes [AppTheme.lightTheme] and [AppTheme.darkTheme] — the two entry
/// points consumed by `MaterialApp` (see `lib/app.dart`). These getter
/// names/signatures are intentionally stable; do not rename them.
///
/// The theme is fully token-driven (see `lib/core/theme/`): colors come from
/// [AppColors], text styles from [AppTextStyles], radii from [AppRadius], and
/// spacing from [AppSpacing]. Both light and dark variants share the same
/// structure so components inherit a cohesive, premium, iOS-style look.
///
/// Premium/iOS notes:
///   * The app bar is clean and minimal (surface background, `elevation: 0`,
///     `surfaceTintColor` transparent, a barely-there scrolled-under
///     elevation). A truly translucent/frosted app bar is composed at the
///     widget level with a `BackdropFilter` over this surface treatment; the
///     theme provides the flat, tint-free base that lets that read cleanly.
///   * The bottom navigation background is transparent so the glass dock
///     (`AppGlass`) can render its own blurred, translucent surface without a
///     competing opaque bar behind it.
///   * Sheets, cards, chips, and inputs all use [AppRadius]/[AppColors] tokens
///     so glass buttons and translucent surfaces sit on a consistent system.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    const textPrimary = AppColors.textPrimary;
    const textSecondary = AppColors.textSecondary;
    const textHint = AppColors.textHint;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(
        primary: textPrimary,
        secondary: textSecondary,
        hint: textHint,
      ),
      appBarTheme: _appBarTheme(
        background: AppColors.surface,
        foreground: textPrimary,
        overlay: SystemUiOverlayStyle.dark,
      ),
      cardTheme: _cardTheme(
        color: AppColors.card,
        border: AppColors.border,
        shadow: Colors.black.withOpacity(0.05),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.surfaceAlt,
        border: AppColors.border,
        hint: textHint,
        label: textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        // Transparent so the premium glass dock (AppGlass) renders its own
        // blurred, translucent surface without a competing opaque bar.
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(
        background: AppColors.surfaceAlt,
        border: AppColors.border,
        label: textPrimary,
      ),
      bottomSheetTheme: _bottomSheetTheme(AppColors.surface),
      dialogTheme: _dialogTheme(
        background: AppColors.surface,
        title: textPrimary,
      ),
      snackBarTheme: _snackBarTheme(
        background: AppColors.secondary,
        content: Colors.white,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    // Dark surface ramp mirrors the design's dark column
    // (background #121212, surface #1E1E1E, surfaceAlt #2C2C2C, border #3A3A3A).
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);
    const darkBorder = Color(0xFF3A3A3A);
    const darkDivider = Color(0xFF2A2A2A);
    const darkTextPrimary = Color(0xFFF5F5F5);
    const darkTextSecondary = Color(0xFFB0B0B0);
    const darkTextHint = Color(0xFF757575);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        surface: darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        outline: darkBorder,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(
        primary: darkTextPrimary,
        secondary: darkTextSecondary,
        hint: darkTextHint,
      ),
      appBarTheme: _appBarTheme(
        background: darkSurface,
        foreground: darkTextPrimary,
        overlay: SystemUiOverlayStyle.light,
      ),
      cardTheme: _cardTheme(
        color: AppColors.darkSurfaceAlt,
        border: darkBorder,
        shadow: Colors.black.withOpacity(0.2),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.darkSurfaceAlt,
        border: darkBorder,
        hint: darkTextHint,
        label: darkTextSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        // Transparent so the premium glass dock (AppGlass) renders its own
        // blurred, translucent surface without a competing opaque bar.
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: darkTextHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(
        background: AppColors.darkSurfaceAlt,
        border: darkBorder,
        label: darkTextPrimary,
      ),
      bottomSheetTheme: _bottomSheetTheme(darkSurface),
      dialogTheme: _dialogTheme(
        background: darkSurface,
        title: darkTextPrimary,
      ),
      snackBarTheme: _snackBarTheme(
        background: AppColors.darkSurfaceAlt,
        content: darkTextPrimary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared builders — token-driven so light/dark stay in lock-step.
  // ---------------------------------------------------------------------------

  /// Builds the [TextTheme] from the shared [AppTextStyles] scale, applying the
  /// per-mode text colors. Sizes/weights are preserved from the existing scale
  /// so no screen shifts visually; only the source of truth becomes the tokens.
  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color hint,
  }) {
    return TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: primary),
      displayMedium: AppTextStyles.h2.copyWith(color: primary),
      displaySmall: AppTextStyles.h3.copyWith(color: primary),
      headlineLarge: AppTextStyles.h3.copyWith(fontSize: 22, color: primary),
      headlineMedium: AppTextStyles.h4.copyWith(color: primary),
      headlineSmall: AppTextStyles.h5.copyWith(color: primary),
      titleLarge: AppTextStyles.h6.copyWith(color: primary),
      titleMedium: AppTextStyles.labelLarge.copyWith(color: primary),
      titleSmall: AppTextStyles.labelMedium.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: hint),
    );
  }

  /// Clean, minimal, iOS-style app bar. Surface background, no base elevation,
  /// tint-free (so it reads flat like iOS), a whisper of scrolled-under
  /// elevation, centered [AppTextStyles.h5] title, and a premium back control.
  static AppBarTheme _appBarTheme({
    required Color background,
    required Color foreground,
    required SystemUiOverlayStyle overlay,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      // Kill the Material 3 surface tint so the bar stays flat/clean and any
      // widget-level translucent (glass) treatment reads correctly.
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.06),
      centerTitle: true,
      titleSpacing: AppSpacing.lg,
      // Premium back control: refined size + consistent foreground color.
      iconTheme: IconThemeData(color: foreground, size: 22),
      actionsIconTheme: IconThemeData(color: foreground, size: 22),
      titleTextStyle: AppTextStyles.h5.copyWith(color: foreground),
      systemOverlayStyle: overlay,
    );
  }

  static CardTheme _cardTheme({
    required Color color,
    required Color border,
    required Color shadow,
  }) {
    return CardTheme(
      color: color,
      elevation: 0,
      shadowColor: shadow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
        side: BorderSide(color: border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTextStyles.button,
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({
    required Color fill,
    required Color border,
    required Color hint,
    required Color label,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(AppColors.primary, 1.5),
      errorBorder: outline(AppColors.error),
      focusedErrorBorder: outline(AppColors.error, 1.5),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: hint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: label),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }

  static ChipThemeData _chipTheme({
    required Color background,
    required Color border,
    required Color label,
  }) {
    return ChipThemeData(
      backgroundColor: background,
      labelStyle: AppTextStyles.labelMedium.copyWith(color: label),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      side: BorderSide(color: border),
    );
  }

  /// Bottom sheet base. `xl` top radius matches the design's sheet spec and the
  /// glass sheet treatment; a widget-level `BackdropFilter` can layer frost on
  /// top of this surface for the premium translucent look.
  static BottomSheetThemeData _bottomSheetTheme(Color background) =>
      BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      );

  static DialogTheme _dialogTheme({
    required Color background,
    required Color title,
  }) =>
      DialogTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl - 4),
        ),
        titleTextStyle: AppTextStyles.h5.copyWith(color: title),
      );

  static SnackBarThemeData _snackBarTheme({
    required Color background,
    required Color content,
  }) =>
      SnackBarThemeData(
        backgroundColor: background,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: content),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        behavior: SnackBarBehavior.floating,
      );
}
