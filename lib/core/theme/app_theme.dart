import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central app theme — modern minimal design language.
///
/// Light: soft off-white page with pure-white floating cards, fresh green
/// accent, hairline-free surfaces and generous rounding.
/// Dark: clean near-black surface stack with the same green accent.
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
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryBg,
        onPrimaryContainer: AppColors.primaryDeep,
        secondary: AppColors.primary,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        hint: AppColors.textHint,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme:
            IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme(
        surface: Colors.white,
        border: AppColors.border,
      ),
      textButtonTheme: _textButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.surfaceAlt,
        hint: AppColors.textHint,
        label: AppColors.textSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(
        bg: AppColors.primaryBg,
        fg: AppColors.primaryDeep,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.textSecondary,
        style: ListTileStyle.list,
      ),
      switchTheme: _switchTheme(
        offTrack: AppColors.border,
        offThumb: Colors.white,
      ),
      splashColor: AppColors.primary.withOpacity(0.06),
      highlightColor: AppColors.primary.withOpacity(0.04),
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
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.darkSurfaceAlt,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.primary,
        surface: AppColors.darkCard,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        hint: AppColors.darkTextHint,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        iconTheme:
            IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        actionsIconTheme:
            IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme(
        surface: AppColors.darkCard,
        border: AppColors.darkBorder,
      ),
      textButtonTheme: _textButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.darkSurfaceAlt,
        hint: AppColors.darkTextHint,
        label: AppColors.darkTextSecondary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: _chipTheme(
        bg: AppColors.darkSurfaceAlt,
        fg: AppColors.primaryLight,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topXl),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        contentTextStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextPrimary),
        shape:
            const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.darkTextSecondary,
        style: ListTileStyle.list,
      ),
      switchTheme: _switchTheme(
        offTrack: AppColors.darkBorder,
        offThumb: AppColors.darkTextHint,
      ),
      splashColor: AppColors.primary.withOpacity(0.12),
      highlightColor: AppColors.primary.withOpacity(0.06),
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

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 54),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTextStyles.button,
        ),
      );

  static FilledButtonThemeData get _filledButtonTheme =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTextStyles.button,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required Color surface,
    required Color border,
  }) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge
              .copyWith(fontWeight: FontWeight.w600),
        ),
      );

  static ChipThemeData _chipTheme({required Color bg, required Color fg}) =>
      ChipThemeData(
        backgroundColor: bg,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      );

  static SwitchThemeData _switchTheme({
    required Color offTrack,
    required Color offThumb,
  }) =>
      SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return offThumb;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return offTrack;
        }),
        trackOutlineColor:
            MaterialStateProperty.all(Colors.transparent),
        trackOutlineWidth: MaterialStateProperty.all<double>(0),
      );

  static InputDecorationTheme _inputDecorationTheme({
    required Color fill,
    required Color hint,
    required Color label,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: outline(Colors.transparent),
      enabledBorder: outline(Colors.transparent),
      focusedBorder: outline(AppColors.primary, 1.5),
      errorBorder: outline(AppColors.error),
      focusedErrorBorder: outline(AppColors.error, 1.5),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: hint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: label),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
    );
  }
}
