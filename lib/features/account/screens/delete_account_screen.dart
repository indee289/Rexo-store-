import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/account_deletion_provider.dart';

/// Full-screen, routed Delete Account flow (NOT a dialog) — rebuilt layout.
///
/// Reached from Settings → Danger zone → Delete account
/// (`/settings/delete-account`). Explains exactly what happens, requires an
/// explicit acknowledgement, and on confirmation calls the server-side deletion
/// (identity derived from the authenticated session), signs the user out, and
/// returns them to login.
///
/// Old layout: `PremiumAppBar` over a flat `ListView` — a red warning
/// `Container`, two bare `Text` headings each followed by hand-built `•`
/// bullet rows, a Material `Checkbox`, and a `FilledButton`.
///
/// New layout: collapsing large title, the warning as a red-edged card, the
/// two explanations as proper grouped sections with icon rows (so "deleted"
/// and "retained" are visually distinct rather than two identical bullet
/// lists), and the acknowledgement as a full-width tappable card.
///
/// The deletion call, sign-out, routing and copy are unchanged.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _acknowledged = false;

  Future<void> _confirmDelete() async {
    final result =
        await ref.read(accountDeletionProvider.notifier).deleteAccount(
              reason: 'in-app account deletion',
            );

    if (!mounted) return;

    if (!result.isSuccess) {
      showGlassSnackBar(
        context,
        message: result.error ?? 'Account deletion failed.',
        tone: GlassToastTone.error,
      );
      return;
    }

    // Personal data is deleted/anonymized. Terminate the session and route the
    // user back to the logged-out auth screen.
    await ref.read(authProvider.notifier).signOut();
    if (!mounted) return;

    showGlassSnackBar(
      context,
      message: 'Your account has been deleted.',
      tone: GlassToastTone.success,
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountDeletionProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(title: 'Delete account', showBack: true),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: GlassCard(
                borderRadius: AppRadius.allLg,
                rim: AppColors.error.withOpacity(0.28),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlassIconBubble(
                      icon: AppIcons.warning_2,
                      color: AppColors.error,
                      size: 36,
                      iconSize: 19,
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Text(
                        'This permanently deletes your Campster account. '
                        'This action cannot be undone.',
                        style: AppTextStyles.subheadline.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: GlassSection(
              title: 'What gets deleted',
              children: [
                GlassRow(
                  icon: AppIcons.user,
                  iconColor: AppColors.error,
                  title: 'Your profile',
                  subtitle: 'Name, username, photo, bio and contact info',
                  showChevron: false,
                ),
                GlassRow(
                  icon: AppIcons.notification,
                  iconColor: AppColors.error,
                  title: 'Notifications and device data',
                  subtitle: 'Including push registrations',
                  showChevron: false,
                ),
                GlassRow(
                  icon: AppIcons.message_text,
                  iconColor: AppColors.error,
                  title: 'Your chat messages',
                  subtitle: 'Removed from conversations',
                  showChevron: false,
                ),
                GlassRow(
                  icon: AppIcons.link_2,
                  iconColor: AppColors.error,
                  title: 'Linked accounts and addresses',
                  subtitle: 'Social links and saved addresses',
                  showChevron: false,
                ),
                GlassRow(
                  icon: AppIcons.logout,
                  iconColor: AppColors.error,
                  title: 'All sessions',
                  subtitle: 'You are signed out on every device',
                  showChevron: false,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: GlassSection(
              title: 'What we must keep',
              children: [
                GlassRow(
                  icon: AppIcons.receipt,
                  iconColor: AppColors.info,
                  title: 'Financial records',
                  subtitle: 'Wallet, deposits, withdrawals and transactions '
                      'are retained in anonymized form to meet Indian tax '
                      'and financial-regulation requirements, as described '
                      'in our Privacy Policy. They are no longer linked to '
                      'your personal identity.',
                  showChevron: false,
                ),
              ],
            ),
          ),

          // Acknowledgement — the whole card is the target, not a 20px box.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: GlassCard(
                borderRadius: AppRadius.allLg,
                rim: _acknowledged ? AppColors.error.withOpacity(0.32) : null,
                onTap: state.isLoading
                    ? null
                    : () => setState(() => _acknowledged = !_acknowledged),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CheckMark(checked: _acknowledged),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Text(
                        'I understand this is permanent and my account and '
                        'personal data will be deleted.',
                        style: AppTextStyles.subheadline.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  GlassButton.destructive(
                    label: 'Delete my account permanently',
                    loading: state.isLoading,
                    size: GlassButtonSize.large,
                    onPressed: (!_acknowledged || state.isLoading)
                        ? null
                        : _confirmDelete,
                  ),
                  AppSpacing.gapSm,
                  GlassButton.glass(
                    label: 'Cancel',
                    onPressed: state.isLoading ? null : () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square check indicator for the acknowledgement card.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.error : Colors.transparent,
        borderRadius: AppRadius.allXs,
        border: Border.all(
          color: checked ? AppColors.error : AppColors.systemGray3,
          width: 1.6,
        ),
      ),
      child: checked
          // Material's check glyph: a plain tick has no Phosphor equivalent in
          // the app's icon set, and this one is always available.
          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
          : null,
    );
  }
}
