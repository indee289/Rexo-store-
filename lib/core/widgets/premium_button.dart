import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// Visual variants for the deprecated [PremiumButton].
///
/// Each one maps onto a [GlassButtonVariant]:
/// `filled`/`tonal` → filled, `outline` → outline, `ghost` → ghost,
/// `glass` → glass.
enum PremiumButtonVariant { filled, tonal, outline, ghost, glass }

/// **Deprecated — migration shim.** Use [GlassButton] directly.
///
/// Forwards to [GlassButton] so the ~72 remaining call-sites render the real
/// pill-shaped glass button. The previous styling (48px tall, 26px radius,
/// flat Instagram-blue fill, opacity-only press feedback) has been removed
/// outright; nothing can render it any more.
///
/// Scheduled for deletion once every call-site is migrated.
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Ignored. The filled variant is always a brand-red gradient now.
  final bool gradient;
  final bool expand;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PremiumButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.gradient = false,
    this.expand = true,
  });

  GlassButtonVariant get _mapped {
    switch (variant) {
      case PremiumButtonVariant.filled:
      case PremiumButtonVariant.tonal:
        return GlassButtonVariant.filled;
      case PremiumButtonVariant.outline:
        return GlassButtonVariant.outline;
      case PremiumButtonVariant.ghost:
        return GlassButtonVariant.ghost;
      case PremiumButtonVariant.glass:
        return GlassButtonVariant.glass;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      onPressed: onPressed,
      variant: _mapped,
      icon: icon,
      loading: loading,
      expand: expand,
    );
  }
}
