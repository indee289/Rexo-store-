import 'package:flutter/animation.dart';

/// Centralized motion tokens (Theme_System token set).
///
/// Durations and curves so every animation feels part of one system.
/// Designed to pair with `flutter_animate` (already a dependency).
/// See design "Motion tokens".
abstract class AppMotion {
  AppMotion._();

  /// Durations.
  static const Duration fast = Duration(milliseconds: 150); // taps, toggles
  static const Duration base = Duration(milliseconds: 250); // most transitions
  static const Duration slow = Duration(milliseconds: 400); // page/hero

  /// Curves.
  static const Curve standard = Curves.easeOutCubic; // enter
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve exit = Curves.easeInCubic;

  /// Staggered list entrance: item `i` starts at `i * stagger`.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Press-scale factor applied to primitives on press-down.
  static const double pressScale = 0.97;
}
