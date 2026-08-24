import 'package:flutter/widgets.dart';

/// 8pt-based spacing scale (Theme_System token set).
///
/// Use these tokens instead of arbitrary paddings/margins so layout rhythm
/// stays consistent across every screen. See design "Spacing scale".
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal content padding used by screens/lists.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: lg);

  /// Convenience gap widgets for vertical/horizontal spacing.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}
