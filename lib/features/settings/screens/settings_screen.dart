import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Settings',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance section
            _buildSectionHeader('Appearance'),
            _buildThemeSelector(context, ref, settings),
            const SizedBox(height: AppSpacing.lg),

            // Account section
            _buildSectionHeader('Account'),
            _buildMenuItem(
              context: context,
              icon: Iconsax.edit,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.link,
              title: 'Linked Accounts',
              subtitle: 'Manage connected social accounts',
              onTap: () => context.push('/linked-accounts'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.shield_tick,
              title: 'KYC Verification',
              subtitle: 'Verify your identity',
              onTap: () => context.push('/kyc'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.crown_1,
              title: 'Rexo Program',
              subtitle: 'Apply to sell on the marketplace',
              onTap: () => _showRexoProgramInfo(context),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Security section
            _buildSectionHeader('Security'),
            _buildMenuItem(
              context: context,
              icon: Iconsax.mobile,
              title: 'Sessions & Devices',
              subtitle: 'Manage active sessions',
              onTap: () => context.push('/sessions'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.shield_tick,
              title: 'Two-Factor Authentication',
              subtitle: 'Secure your account with TOTP',
              onTap: () => context.push('/two-factor-auth'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.lock_1,
              title: 'Change Password',
              subtitle: 'Send password reset email',
              onTap: () => _handleChangePassword(context),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              context: context,
              icon: Iconsax.notification,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: settings.notificationsEnabled,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(value);
              },
            ),
            _buildSwitchTile(
              context: context,
              icon: Iconsax.sms,
              title: 'Email Notifications',
              subtitle: 'Receive email updates',
              value: settings.emailNotificationsEnabled,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setEmailNotificationsEnabled(value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Legal section
            _buildSectionHeader('Legal'),
            _buildMenuItem(
              context: context,
              icon: Iconsax.shield_tick,
              title: 'Privacy Policy',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.document_text,
              title: 'Terms of Service',
              onTap: () => context.push('/terms-of-service'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.message_question,
              title: 'Help & Support',
              onTap: () => context.push('/help-support'),
            ),
            _buildMenuItem(
              context: context,
              icon: Iconsax.info_circle,
              title: 'About',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(Iconsax.logout, color: AppColors.error),
                  label: Text(
                    'Logout',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.allMd,
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SectionHeader(title: title),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildThemeOption(
            context,
            ref: ref,
            label: 'Light',
            icon: Iconsax.sun_1,
            mode: ThemeMode.light,
            isSelected: settings.themeMode == ThemeMode.light,
          ),
          _buildThemeOption(
            context,
            ref: ref,
            label: 'Dark',
            icon: Iconsax.moon,
            mode: ThemeMode.dark,
            isSelected: settings.themeMode == ThemeMode.dark,
          ),
          _buildThemeOption(
            context,
            ref: ref,
            label: 'System',
            icon: Iconsax.mobile,
            mode: ThemeMode.system,
            isSelected: settings.themeMode == ThemeMode.system,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
            borderRadius: AppRadius.allSm,
            border: isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: theme.colorScheme.onSurface.withOpacity(0.6), size: 22),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          : null,
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: 18,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: theme.colorScheme.onSurface.withOpacity(0.6), size: 22),
      title: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Rexo',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: AppRadius.allSm,
        child: Image.asset(
          'assets/logo.png',
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => const Icon(
            Iconsax.crown_1,
            color: AppColors.primary,
            size: 40,
          ),
        ),
      ),
      children: [
        Text(
          'Rexo — a premium influencer marketing platform connecting brands and '
          'creators for campaigns, collaborations and payouts.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.4),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '© 2024 Rexo. All rights reserved.',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showRexoProgramInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rexo Program', style: AppTextStyles.h6),
        content: Text(
          'The Rexo Program allows creators to sell products on the marketplace. '
          'Contact support to apply or check your eligibility.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangePassword(BuildContext context) async {
    final user = SupabaseService.currentUser;
    if (user?.email == null) return;

    try {
      await SupabaseService.resetPassword(user!.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reset email. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: AppTextStyles.h6),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).signOut();
    }
  }
}
