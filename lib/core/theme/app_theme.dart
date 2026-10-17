import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central app theme — **Instagram-inspired, light only**.
///
/// Pure white surfaces, hairline separators, blue accents, no shadows.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Light theme (Instagram)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      splashFactory: NoSplash.splashFactory, // IG has no ripple
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryBg,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(),

      // ── Instagram-style app bar ──────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
        titleTextStyle: AppTextStyles.title3.copyWith(
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Instagram-style card (no shadow, just white) ─────────────────────
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        margin: EdgeInsets.zero,
      ),

      // ── IG "Follow" style filled blue button ─────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 44),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),

      // ── IG "Following" bordered secondary button ─────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTextStyles.button
              .copyWith(color: AppColors.textPrimary),
          side: const BorderSide(color: AppColors.border, width: 1),
          backgroundColor: AppColors.background,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),

      // ── IG plain text button (blue links) ────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        ),
      ),

      // ── IG search bar / input (gray fill, no border) ─────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        labelStyle:
            AppTextStyles.subheadline.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle:
            AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),

      // ── IG-style tag chip ────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primaryBg,
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.surfaceAlt.withOpacity(0.5),
        labelStyle: AppTextStyles.footnote
            .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle:
            AppTextStyles.footnote.copyWith(color: AppColors.primary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
      ),

      // ── Bottom sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.background,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topXl),
        clipBehavior: Clip.antiAlias,
        showDragHandle: true,
        dragHandleColor: AppColors.systemGray3,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        titleTextStyle: AppTextStyles.title3
            .copyWith(color: AppColors.textPrimary),
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      ),

      // ── Bottom nav (IG-style — light, no elevation) ──────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textPrimary,
        selectedLabelStyle: AppTextStyles.caption2,
        unselectedLabelStyle: AppTextStyles.caption2,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // ── IG toggle (blue) ─────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
            (_) => Colors.white),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.systemGray4;
        }),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),

      // ── Checkbox / Radio (blue) ──────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.systemGray3, width: 1.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.systemGray3;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
      ),

      // ── IG hairline dividers (1px light gray) ────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryBg,
        selectionHandleColor: AppColors.primary,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: Colors.white),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        elevation: 0,
      ),

      // ── IG list tile (minimal, no color) ─────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        selectedTileColor: AppColors.surfaceAlt,
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
        titleTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        subtitleTextStyle: AppTextStyles.footnote
            .copyWith(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minLeadingWidth: 28,
        horizontalTitleGap: AppSpacing.md,
        shape: const RoundedRectangleBorder(),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // ── IG tab bar (Photos/Reels/Tagged style) ──────────────────────────
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.subheadline,
        indicatorColor: AppColors.textPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
      ),
    );
  }

  // Dark alias — points to light (app is light-only).
  static ThemeData get darkTheme => lightTheme;

  static TextTheme _buildTextTheme() {
    const Color primary = AppColors.textPrimary;
    const Color secondary = AppColors.textSecondary;
    const Color hint = AppColors.textHint;

    return TextTheme(
      displayLarge: AppTextStyles.largeTitle.copyWith(color: primary),
      displayMedium: AppTextStyles.title1.copyWith(color: primary),
      displaySmall: AppTextStyles.title2.copyWith(color: primary),
      headlineLarge: AppTextStyles.title1.copyWith(color: primary),
      headlineMedium: AppTextStyles.title2.copyWith(color: primary),
      headlineSmall: AppTextStyles.title3.copyWith(color: primary),
      titleLarge: AppTextStyles.title3.copyWith(color: primary),
      titleMedium: AppTextStyles.headline.copyWith(color: primary),
      titleSmall: AppTextStyles.subheadline
          .copyWith(color: primary, fontWeight: FontWeight.w600),
      bodyLarge: AppTextStyles.body.copyWith(color: primary),
      bodyMedium: AppTextStyles.body.copyWith(color: primary),
      bodySmall: AppTextStyles.subheadline.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: hint),
    );
  }
}
