import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_glass.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central app theme — **Campster premium, light only**.
///
/// The theme's job here is mostly *subtractive*: it strips the saturated
/// fills, surface tints, elevations and ink ripples Material paints by default,
/// so the components in `core/widgets/glass/` supply the real material. Every
/// component theme below sets zero elevation and a transparent
/// `surfaceTintColor`, because Material 3's tint overlay would otherwise shift
/// the colour of every surface away from the palette.
///
/// Component themes for raw Material widgets (`ElevatedButton`, `Card`,
/// `TextField`, ...) are still defined, tuned to brand red and the glass
/// radius ramp. They exist as a safety net for any call-site not yet migrated
/// to the `Glass*` equivalents, so no screen can render in the retired blue
/// Instagram style at any point during the migration.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Light theme (Liquid Glass)
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      // Opaque on purpose. `GlassScaffold` overrides this to transparent and
      // paints `GlassBackdrop` behind itself; a globally transparent scaffold
      // would leave any plain `Scaffold` with no background at all.
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
      // Glass components run their own spring press animation, so Material's
      // ink ripple would double up and smear across the blur.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryBg,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
        onError: AppColors.textOnPrimary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        // Kill the M3 surface tint everywhere at once.
        surfaceTint: Colors.transparent,
      ),

      textTheme: _buildTextTheme(),

      // ── App bar — glass is painted by GlassAppBar; strip Material's ──────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: AppTextStyles.title3.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        // Dark status-bar icons, because the backdrop is light.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Card — translucent, large radius, soft glass shadow ─────────────
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allLg,
          side: BorderSide(color: AppGlass.border(false), width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Filled button — brand red pill ──────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.7),
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 15),
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 15),
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
      ),

      // ── Outlined button — brand rim on glass ────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.transparent,
          textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 15),
          side: const BorderSide(color: AppColors.primaryRim, width: 1.2),
          minimumSize: const Size(double.infinity, 50),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillAll,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
      ),

      // ── Text button — red label, no chrome ──────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontSize: 15,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          highlightColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),

      // ── Input — recessed glass well, red focus rim ───────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        labelStyle:
            AppTextStyles.subheadline.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle:
            AppTextStyles.footnote.copyWith(color: AppColors.primary),
        errorStyle: AppTextStyles.footnote.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        disabledBorder: _inputBorder(AppColors.divider),
        focusedBorder: _inputBorder(AppColors.primaryRim, 1.4),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, 1.4),
      ),

      // ── Chip — frosted pill ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary.withOpacity(0.14),
        secondarySelectedColor: AppColors.primary.withOpacity(0.14),
        deleteIconColor: AppColors.textSecondary,
        disabledColor: AppColors.surfaceAlt.withOpacity(0.4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        pressElevation: 0,
        labelStyle: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textSecondary),
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),

      // ── Bottom sheet — fully transparent; GlassSheet paints the pane ────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topXxl),
        clipBehavior: Clip.none,
        // GlassSheet draws its own grab handle.
        showDragHandle: false,
        dragHandleColor: AppColors.textPrimary.withOpacity(0.18),
        modalBarrierColor: AppGlass.scrim(false),
      ),

      // ── Dialog — transparent; GlassDialog paints the pane ───────────────
      dialogTheme: DialogTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        titleTextStyle:
            AppTextStyles.title2.copyWith(color: AppColors.textPrimary),
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),

      // ── Bottom nav — transparent; GlassNavBar paints the dock ───────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle:
            AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.14),
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorShape:
            const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),

      // ── Switch — brand red track ─────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.white),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceAlt;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primaryRim;
          }
          return AppColors.border;
        }),
        trackOutlineWidth: MaterialStateProperty.all(1),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.systemGray3, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.systemGray3;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceAlt,
        thumbColor: Colors.white,
        overlayColor: AppColors.primary.withOpacity(0.12),
        trackHeight: 5,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withOpacity(0.22),
        selectionHandleColor: AppColors.primary,
      ),

      // ── Snackbar — transparent; showGlassSnackBar paints the toast ──────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.transparent,
        contentTextStyle:
            AppTextStyles.subheadline.copyWith(color: AppColors.textPrimary),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        elevation: 0,
      ),

      // ── List tile — transparent so the glass pane behind shows ──────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primary.withOpacity(0.10),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.primary,
        titleTextStyle:
            AppTextStyles.headline.copyWith(color: AppColors.textPrimary),
        subtitleTextStyle:
            AppTextStyles.footnote.copyWith(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minLeadingWidth: 28,
        horizontalTitleGap: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),

      // ── Tab bar — red pill indicator (GlassTabBar is preferred) ─────────
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.9),
          borderRadius: AppRadius.allSm,
        ),
        textStyle: AppTextStyles.footnote.copyWith(color: Colors.white),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white.withOpacity(0.92),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allMd,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        textStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  /// Dark alias — points to light. The app is light-only by product decision,
  /// and the Appearance picker in Settings is retained for compatibility only.
  static ThemeData get darkTheme => lightTheme;

  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: AppRadius.allMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }

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
