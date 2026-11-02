import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../features/blocks/providers/block_provider.dart';
import '../../features/reports/providers/report_provider.dart';
import '../theme/app_colors.dart';
import 'glass/glass.dart';

/// Overflow ("More") menu shown on another user's profile / chat surfaces.
///
/// Provides the two user-facing safety actions Google Play expects for UGC:
///   • Report — routes to the full-screen report flow (`/report`).
///   • Block / Unblock — toggles a block relationship via [blockActionsProvider].
///
/// This is an action menu, NOT the report flow itself — the report flow is a
/// dedicated full-screen route.
///
/// Rebuilt: was a Material `PopupMenuButton` whose items were `ListTile`s, with
/// an `AlertDialog` block confirmation and raw `ScaffoldMessenger` snackbars.
/// It is now a [GlassIconButton] that opens a glass sheet of grouped rows, with
/// the shared confirm dialog and toasts, so it matches the surfaces it sits on.
/// The actions, the route and the providers are unchanged.
class UserActionsMenu extends ConsumerWidget {
  final String targetUserId;
  final String targetLabel;

  const UserActionsMenu({
    super.key,
    required this.targetUserId,
    required this.targetLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iBlocked = ref.watch(iBlockedProvider(targetUserId));
    final isBlocked = iBlocked.maybeWhen(data: (v) => v, orElse: () => false);

    return GlassIconButton(
      icon: AppIcons.more,
      tooltip: 'More actions',
      size: 36,
      iconSize: 19,
      onTap: () => _showMenu(context, ref, isBlocked),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, bool isBlocked) {
    showGlassSheet<void>(
      context: context,
      title: targetLabel,
      subtitle: 'Safety actions',
      child: Builder(
        builder: (sheetContext) => GlassGroup(
          children: [
            GlassRow(
              icon: AppIcons.flag,
              title: 'Report',
              subtitle: 'Tell us what is wrong',
              showChevron: false,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/report', extra: {
                  'targetType': ReportTargetType.user,
                  'targetId': targetUserId,
                  'targetLabel': targetLabel,
                });
              },
            ),
            if (isBlocked)
              GlassRow(
                icon: AppIcons.user_tick,
                iconColor: AppColors.success,
                title: 'Unblock',
                subtitle: 'Allow messages again',
                showChevron: false,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _unblock(context, ref);
                },
              )
            else
              GlassRow(
                icon: AppIcons.user_remove,
                title: 'Block',
                subtitle: 'Stop all contact both ways',
                destructive: true,
                showChevron: false,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmAndBlock(context, ref);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndBlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Block $targetLabel?',
      message: 'They will no longer be able to message you, and you will not '
          'see each other across the app. You can unblock them at any time.',
      icon: AppIcons.user_remove,
      confirmLabel: 'Block',
      destructive: true,
    );
    if (!confirmed) return;

    final ok =
        await ref.read(blockActionsProvider.notifier).block(targetUserId);
    if (!context.mounted) return;
    showGlassSnackBar(
      context,
      message: ok ? 'User blocked' : "Couldn't block user",
      tone: ok ? GlassToastTone.success : GlassToastTone.error,
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(blockActionsProvider.notifier).unblock(targetUserId);
    if (!context.mounted) return;
    showGlassSnackBar(
      context,
      message: ok ? 'User unblocked' : "Couldn't unblock user",
      tone: ok ? GlassToastTone.success : GlassToastTone.error,
    );
  }
}
