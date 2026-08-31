import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central app theme — premium Material 3 with bold indigo design system.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.surfaceAlt,
        secondary: AppColors.accentPurple,
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
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        hint: AppColors.textHint,
      ),
      appBarTheme: _appBarTheme(
        background: AppColors.background,
        foreground: AppColors.textPrimary,
        overlay: SystemUiOverlayStyle.dark,
      ),
      cardTheme: _cardTheme(
        color: AppColors.card,
        border: AppColors.border,
        shadow: Colors.black.withOpacity(0.04),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.surfaceAlt,
        border: AppColors.border,
        hint: AppColors.textHint,
        label: AppColors.textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
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
        label: AppColors.textPrimary,
      ),
      bottomSheetTheme: _bottomSheetTheme(AppColors.surface),
      dialogTheme: _dialogTheme(
        background: AppColors.surface,
        title: AppColors.textPrimary,
      ),
      snackBarTheme: _snackBarTheme(
        background: AppColors.textPrimary,
        content: Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.textSecondary,
        style: ListTileStyle.list,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.darkSurfaceAlt,
        secondary: AppColors.accentPurple,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        hint: AppColors.darkTextHint,
      ),
      appBarTheme: _appBarTheme(
        background: AppColors.darkBackground,
        foreground: AppColors.darkTextPrimary,
        overlay: SystemUiOverlayStyle.light,
      ),
      cardTheme: _cardTheme(
        color: AppColors.darkCard,
        border: AppColors.darkBorder,
        shadow: Colors.black.withOpacity(0.3),
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.darkSurfaceAlt,
        border: AppColors.darkBorder,
        hint: AppColors.darkTextHint,
        label: AppColors.darkTextSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(
        background: AppColors.darkSurfaceAlt,
        border: AppColors.darkBorder,
        label: AppColors.darkTextPrimary,
      ),
      bottomSheetTheme: _bottomSheetTheme(AppColors.darkSurface),
      dialogTheme: _dialogTheme(
        background: AppColors.darkSurface,
        title: AppColors.darkTextPrimary,
      ),
      snackBarTheme: _snackBarTheme(
        background: AppColors.darkSurfaceAlt,
        content: AppColors.darkTextPrimary,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.darkTextSecondary,
        style: ListTileStyle.list,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return AppColors.darkTextHint;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return AppColors.darkBorder;
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared builders
  // ---------------------------------------------------------------------------
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

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color foreground,
    required SystemUiOverlayStyle overlay,
  }) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
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
      focusedBorder: outline(AppColors.primary, 2),
      errorBorder: outline(AppColors.error),
      focusedErrorBorder: outline(AppColors.error, 2),
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
