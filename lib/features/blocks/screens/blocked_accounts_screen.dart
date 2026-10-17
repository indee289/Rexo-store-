import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../providers/block_provider.dart';

/// Lists the accounts the current user has blocked, with an Unblock action.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(myBlockedUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Blocked Accounts', showBack: true),
      body: blockedAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Iconsax.user_tick,
              title: 'No blocked accounts',
              subtitle: 'People you block will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final u = users[i];
              final id = (u['uid'] ?? '').toString();
              final name = (u['name'] ?? u['username'] ?? 'User').toString();
              final avatar = u['profileImage'] as String?;
              return ListTile(
                leading: PremiumAvatar(imageUrl: avatar, name: name, size: 44),
                title: Text(name, style: AppTextStyles.bodyMedium),
                subtitle: u['username'] != null
                    ? Text('@${u['username']}', style: AppTextStyles.bodySmall)
                    : null,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref
                        .read(blockActionsProvider.notifier)
                        .unblock(id);
                    ref.invalidate(myBlockedUsersProvider);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Unblocked' : "Couldn't unblock"),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error,
                      ),
                    );
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Iconsax.warning_2,
          title: 'Could not load',
          subtitle: 'Please try again later.',
        ),
      ),
    );
  }
}
