import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../providers/block_provider.dart';

/// Lists the accounts the current user has blocked, with an Unblock action.
///
/// Old layout: `PremiumAppBar` over a `ListView` of Material `ListTile`s, each
/// with a stock `OutlinedButton` trailing, and a bare `CircularProgressIndicator`
/// for loading.
///
/// New layout: collapsing large title reporting the blocked count, and the
/// accounts as one grouped section of rows — a list of 3 blocked users reads as
/// one list rather than three floating tiles.
///
/// `myBlockedUsersProvider` and `blockActionsProvider.unblock` are unchanged.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(myBlockedUsersProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Blocked accounts',
            showBack: true,
            subtitle: blockedAsync.maybeWhen(
              data: (u) => u.isEmpty ? null : '${u.length} blocked',
              orElse: () => null,
            ),
          ),
          blockedAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.user_tick,
                    title: 'No blocked accounts',
                    message: 'People you block will appear here.',
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: GlassSection(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    for (final u in users)
                      _BlockedRow(user: u),
                  ],
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: GlassLoader(),
            ),
            error: (_, __) => SliverFillRemaining(
              hasScrollBody: false,
              child: GlassErrorState(
                title: 'Could not load',
                message: 'Please try again later.',
                onRetry: () => ref.invalidate(myBlockedUsersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedRow extends ConsumerWidget {
  const _BlockedRow({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = (user['uid'] ?? '').toString();
    final name = (user['name'] ?? user['username'] ?? 'User').toString();
    final avatar = user['profileImage'] as String?;
    final username = user['username'];

    return GlassRow(
      title: name,
      subtitle: username == null ? null : '@$username',
      showChevron: false,
      leading: PremiumAvatar(
        imageUrl: avatar,
        name: name,
        size: PremiumAvatar.sizeSm + 8,
      ),
      trailing: GlassButton.outline(
        label: 'Unblock',
        size: GlassButtonSize.small,
        expand: false,
        onPressed: () => _unblock(context, ref, id),
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await ref.read(blockActionsProvider.notifier).unblock(id);
    ref.invalidate(myBlockedUsersProvider);
    if (!context.mounted) return;
    showGlassSnackBar(
      context,
      message: ok ? 'Unblocked' : "Couldn't unblock",
      tone: ok ? GlassToastTone.success : GlassToastTone.error,
    );
  }
}
