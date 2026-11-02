import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../providers/settings_provider.dart';

/// Settings screen — liquid glass, rebuilt layout.
///
/// The previous screen hand-rolled the whole pattern: a fake app bar built from
/// an `IconButton` plus a centred `Text`, a `_GroupCard` that was an opaque
/// white `Container` with inset `Divider`s between rows, `_SettingsItem` /
/// `_ToggleItem` rows with hardcoded `TextStyle`s, and `_DangerButton` tiles.
/// All six of those private widgets are deleted; the screen is now assembled
/// entirely from `GlassSection` / `GlassGroup` / `GlassRow` / `GlassSwitchRow`,
/// so it shares one grouped-list implementation with every other settings-like
/// screen in the app.
///
/// Also replaced: the `showModalBottomSheet` + `ListTile` language picker is a
/// `showGlassSheet`, the logout `AlertDialog` is a `showGlassConfirm`, and the
/// four bare `SnackBar`s are glass toasts.
///
/// Every provider, route, toggle setter and the delete-account flow are
/// unchanged. The large title reads "Settings" rather than the previous
/// "Profile", which collided with the Profile tab.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GlassLargeTitleHeader(
            title: 'Settings',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // ── Identity row, tappable straight into Edit profile ──────────
          SliverToBoxAdapter(
            child: profileAsync.whenOrNull(
                  data: (ps) => _IdentityRow(
                    profile: ps.profile,
                    onEdit: _openEditProfile,
                  ),
                ) ??
                const SizedBox(height: AppSpacing.md),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Account',
              children: [
                GlassRow(
                  icon: AppIcons.edit,
                  title: 'Edit profile',
                  subtitle: 'Update name, photo, bio',
                  onTap: _openEditProfile,
                ),
                GlassRow(
                  icon: AppIcons.link_2,
                  title: 'Linked accounts',
                  subtitle: 'Instagram, YouTube, TikTok',
                  onTap: () => context.push('/linked-accounts'),
                ),
                GlassRow(
                  icon: AppIcons.gift,
                  title: 'Refer & earn',
                  subtitle: 'Invite friends, earn rewards',
                  onTap: () => context.push('/referrals'),
                ),
                GlassRow(
                  icon: AppIcons.global,
                  title: 'Language',
                  trailingText: _languageLabel(ref.watch(localeProvider)),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Security',
              children: [
                GlassRow(
                  icon: AppIcons.shield_tick,
                  title: 'Two-factor auth',
                  subtitle: 'Secure your account with TOTP',
                  trailing: const _RecommendedBadge(),
                  onTap: () => context.push('/two-factor-auth'),
                ),
                GlassRow(
                  icon: AppIcons.monitor,
                  title: 'Active sessions',
                  subtitle: 'Manage signed-in devices',
                  onTap: () => context.push('/sessions'),
                ),
                GlassRow(
                  icon: AppIcons.eye,
                  title: 'Security logs',
                  subtitle: 'View account activity',
                  onTap: () => context.push('/security-logs'),
                ),
                GlassRow(
                  icon: AppIcons.lock,
                  title: 'Change password',
                  subtitle: 'Send a password reset email',
                  onTap: () => _handleChangePassword(context),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Notifications',
              children: [
                GlassSwitchRow(
                  icon: AppIcons.notification,
                  title: 'Push notifications',
                  value: settings.notificationsEnabled,
                  onChanged: notifier.setNotificationsEnabled,
                ),
                GlassSwitchRow(
                  icon: AppIcons.sms,
                  title: 'Email notifications',
                  value: settings.emailNotificationsEnabled,
                  onChanged: notifier.setEmailNotificationsEnabled,
                ),
                GlassSwitchRow(
                  icon: AppIcons.volume_high,
                  title: 'Campaign updates',
                  value: settings.campaignUpdatesEnabled,
                  onChanged: notifier.setCampaignUpdatesEnabled,
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Privacy',
              children: [
                GlassSwitchRow(
                  icon: AppIcons.user,
                  title: 'Public profile',
                  subtitle: 'Let brands discover you',
                  value: settings.publicProfileEnabled,
                  onChanged: notifier.setPublicProfileEnabled,
                ),
                GlassRow(
                  icon: AppIcons.user_remove,
                  title: 'Blocked accounts',
                  subtitle: 'Manage users you have blocked',
                  onTap: () => context.push('/settings/blocked-accounts'),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Support',
              children: [
                GlassRow(
                  icon: AppIcons.message_question,
                  title: 'Help & support',
                  subtitle: 'FAQs and contact',
                  onTap: () => context.push('/help-support'),
                ),
                GlassRow(
                  icon: AppIcons.warning_2,
                  title: 'My disputes',
                  subtitle: 'View raised disputes',
                  onTap: () => context.push('/disputes'),
                ),
                GlassRow(
                  icon: AppIcons.location,
                  title: 'My addresses',
                  subtitle: 'Manage saved addresses',
                  onTap: () => context.push('/addresses'),
                ),
                GlassRow(
                  icon: AppIcons.shield_tick,
                  title: 'Privacy policy',
                  onTap: () => context.push('/privacy-policy'),
                ),
                GlassRow(
                  icon: AppIcons.document_text,
                  title: 'Terms of service',
                  onTap: () => context.push('/terms-of-service'),
                ),
              ],
            ),
          ),

          // ── Destructive actions, in their own group ────────────────────
          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Danger zone',
              children: [
                GlassRow(
                  icon: AppIcons.logout,
                  title: 'Log out',
                  destructive: true,
                  showChevron: false,
                  onTap: () => _handleLogout(context, ref),
                ),
                GlassRow(
                  icon: AppIcons.trash,
                  title: 'Delete account',
                  subtitle: 'Permanently remove your account and data',
                  destructive: true,
                  onTap: _handleDeleteAccount,
                ),
              ],
            ),
          ),

          // Clear the floating nav dock.
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  void _openEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  String _languageLabel(Locale? locale) {
    switch (locale?.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      default:
        return 'System';
    }
  }

  // ── Actions (unchanged behaviour) ───────────────────────────────────────

  Future<void> _handleChangePassword(BuildContext context) async {
    final user = SupabaseService.currentUser;
    if (user?.email == null) return;
    try {
      await SupabaseService.resetPassword(user!.email!);
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: 'Password reset email sent to ${user.email}',
          tone: GlassToastTone.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: 'Failed to send reset email.',
          tone: GlassToastTone.error,
        );
      }
    }
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(localeProvider)?.languageCode;

    await showGlassSheet<void>(
      context: context,
      title: 'Language',
      subtitle: 'Applies across the whole app',
      child: GlassGroup(
        children: [
          _languageRow(context, ref, 'System default', null, current),
          _languageRow(context, ref, 'English', 'en', current),
          _languageRow(context, ref, 'हिन्दी (Hindi)', 'hi', current),
        ],
      ),
    );
  }

  /// One row of the language picker. [code] is `null` for "follow the device".
  Widget _languageRow(
    BuildContext context,
    WidgetRef ref,
    String label,
    String? code,
    String? current,
  ) {
    return GlassRow(
      icon: AppIcons.global,
      title: label,
      showChevron: false,
      trailing: current == code
          ? const Icon(AppIcons.tick_circle, color: AppColors.primary, size: 20)
          : null,
      onTap: () {
        ref
            .read(localeProvider.notifier)
            .setLocale(code == null ? null : Locale(code));
        Navigator.pop(context);
        showGlassSnackBar(
          context,
          message: 'Language updated',
          tone: GlassToastTone.success,
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Log out',
      message: 'Are you sure you want to log out of Campster?',
      icon: AppIcons.logout,
      confirmLabel: 'Log out',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed) {
      ref.read(authProvider.notifier).signOut();
    }
  }

  void _handleDeleteAccount() {
    // Full-screen, routed deletion flow (not a dialog). The screen explains
    // what happens, requires explicit confirmation, and performs the real
    // server-side deletion.
    context.push('/settings/delete-account');
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Identity row
// ─────────────────────────────────────────────────────────────────────────

/// Avatar, name and email as a single glass row that opens Edit profile.
///
/// Replaces the previous opaque white "header card".
class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.profile, required this.onEdit});

  final Map<String, dynamic>? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox(height: AppSpacing.md);

    final name = (profile!['name'] ?? 'User').toString();
    final email = (profile!['email'] ?? '').toString();
    final avatarUrl = profile!['profileImage'] as String?;

    return GlassSection(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        GlassRow(
          title: name,
          subtitle: email.isEmpty ? null : email,
          leading: PremiumAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: PremiumAvatar.sizeSm + 10,
          ),
          onTap: onEdit,
        ),
      ],
    );
  }
}

/// Small green pill marking the recommended security action.
class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: AppColors.success.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Text(
        'Recommended',
        style: AppTextStyles.caption2.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
