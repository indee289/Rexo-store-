import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../features/blocks/providers/block_provider.dart';
import '../../features/reports/providers/report_provider.dart';
import '../theme/app_colors.dart';

/// Overflow ("More") menu shown on another user's profile / chat surfaces.
///
/// Provides the two user-facing safety actions Google Play expects for UGC:
///   • Report — routes to the full-screen report flow (`/report`).
///   • Block / Unblock — toggles a block relationship via [blockActionsProvider].
///
/// This is an action menu (a small popup), NOT the report flow itself — the
/// report flow is a dedicated full-screen route.
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

    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more),
      onSelected: (value) async {
        switch (value) {
          case 'report':
            context.push('/report', extra: {
              'targetType': ReportTargetType.user,
              'targetId': targetUserId,
              'targetLabel': targetLabel,
            });
            break;
          case 'block':
            await _confirmAndBlock(context, ref);
            break;
          case 'unblock':
            await _unblock(context, ref);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'report',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Iconsax.flag),
            title: Text('Report'),
          ),
        ),
        if (isBlocked)
          const PopupMenuItem<String>(
            value: 'unblock',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Iconsax.user_tick),
              title: Text('Unblock'),
            ),
          )
        else
          const PopupMenuItem<String>(
            value: 'block',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Iconsax.user_remove, color: AppColors.error),
              title: Text('Block', style: TextStyle(color: AppColors.error)),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndBlock(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $targetLabel?'),
        content: const Text(
          'They will no longer be able to message you, and you will not see '
          'each other across the app. You can unblock them at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref.read(blockActionsProvider.notifier).block(targetUserId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'User blocked' : "Couldn't block user"),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _unblock(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok =
        await ref.read(blockActionsProvider.notifier).unblock(targetUserId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'User unblocked' : "Couldn't unblock user"),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}
