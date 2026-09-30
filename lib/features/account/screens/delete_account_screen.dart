import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/account_deletion_provider.dart';

/// Full-screen, routed Delete Account flow (NOT a dialog).
///
/// Reached from Settings → Account → Delete Account (`/settings/delete-account`).
/// Explains exactly what happens, requires an explicit acknowledgement, and on
/// confirmation calls the server-side deletion (identity derived from the
/// authenticated session), signs the user out, and returns them to login.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _acknowledged = false;

  Future<void> _confirmDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await ref.read(accountDeletionProvider.notifier).deleteAccount(
              reason: 'in-app account deletion',
            );

    if (!mounted) return;

    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Account deletion failed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Personal data is deleted/anonymized. Terminate the session and route the
    // user back to the logged-out auth screen.
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Your account has been deleted.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountDeletionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Delete Account', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.warning_2, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'This permanently deletes your Rexo Collab account. '
                      'This action cannot be undone.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('What gets deleted', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.sm),
            _bullet('Your profile: name, username, photo, bio and contact info'),
            _bullet('Your notifications and device/push data'),
            _bullet('Your chat messages are removed from conversations'),
            _bullet('Your linked social accounts and saved addresses'),
            _bullet('You are signed out on all devices'),

            const SizedBox(height: AppSpacing.lg),
            Text('What we must keep', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.sm),
            _bullet(
              'Financial records (wallet, deposits, withdrawals and '
              'transactions) are retained in anonymized form to meet Indian '
              'tax and financial-regulation requirements, as described in our '
              'Privacy Policy. They are no longer linked to your personal '
              'identity.',
            ),

            const SizedBox(height: AppSpacing.xl),
            InkWell(
              onTap: state.isLoading
                  ? null
                  : () => setState(() => _acknowledged = !_acknowledged),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acknowledged,
                      onChanged: state.isLoading
                          ? null
                          : (v) => setState(() => _acknowledged = v ?? false),
                      activeColor: AppColors.error,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'I understand this is permanent and my account and '
                          'personal data will be deleted.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (!_acknowledged || state.isLoading) ? null : _confirmDelete,
                child: state.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete my account permanently'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: state.isLoading ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text('•', style: AppTextStyles.bodyMedium),
          ),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
