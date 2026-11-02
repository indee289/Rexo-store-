import 'package:flutter/material.dart';

import 'glass/glass.dart';

/// **Migration shim.** Use [GlassSwitch] directly.
///
/// Forwards to [GlassSwitch], which keeps the same 51x31 Apple sizing but
/// renders the off-state track as a recessed glass well instead of an opaque
/// grey fill, and the on-state in brand red.
///
/// Scheduled for deletion once every call-site is migrated.
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassSwitch(value: value, onChanged: onChanged);
  }
}
