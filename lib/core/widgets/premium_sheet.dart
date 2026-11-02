import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// **Migration shim.** Use [showGlassSheet] directly.
///
/// Forwards to [showGlassSheet], which paints the same frosted treatment with
/// the heavier glass blur, the larger 40px top radius, a specular sheen and a
/// top rim light. The old `_PremiumSheet` pane has been removed.
///
/// Scheduled for deletion once every call-site is migrated.
Future<T?> showPremiumSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showGlassSheet<T>(
    context: context,
    title: title,
    isScrollControlled: isScrollControlled,
    child: child,
  );
}
