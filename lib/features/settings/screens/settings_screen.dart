import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../providers/settings_provider.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left,
                        size: 28, color: AppColors.textPrimary),
                  ),
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User card
                    profileAsync.whenOrNull(
                          data: (profileState) =>
                              _buildUserCard(context, profileState),
                        ) ??
                        const SizedBox(height: AppSpacing.lg),

                    // ACCOUNT section
                    _sectionLabel('ACCOUNT'),
                    _settingsCard([
                      _item(context,
                          icon: Iconsax.edit,
                          iconColor: AppColors.primary,
                          title: 'Edit Profile',
                          subtitle: 'Update name, photo, bio',
                          onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EditProfileScreen()),
                              )),
                      _item(context,
                          icon: Iconsax.link_2,
                          iconColor: AppColors.accentTeal,
                          title: 'Linked Accounts',
                          subtitle: 'Instagram, YouTube, TikTok',
                          onTap: () => context.push('/linked-accounts')),
                      _item(context,
                          icon: Iconsax.verify,
                          iconColor: AppColors.success,
                          title: 'KYC Verification',
                          subtitle: 'Verify your identity',
                          onTap: () => context.push('/kyc')),
                    ]),

                    // SECURITY section
                    _sectionLabel('SECURITY'),
                    _settingsCard([
                      _item(context,
                          icon: Iconsax.shield_tick,
                          iconColor: AppColors.primary,
                          title: 'Two-Factor Auth',
                          subtitle: 'Secure your account with TOTP',
                          trailing: _statusChip('Recommended', AppColors.success),
                          onTap: () => context.push('/two-factor-auth')),
                      _item(context,
                          icon: Iconsax.mobile,
                          iconColor: AppColors.accentIndigo,
                          title: 'Active Sessions',
                          subtitle: 'Manage active sessions',
                          onTap: () => context.push('/sessions')),
                      _item(context,
                          icon: Iconsax.document_text,
                          iconColor: AppColors.warning,
                          title: 'Security Logs',
                          subtitle: 'View account activity',
                          onTap: () => context.push('/security-logs')),
                      _item(context,
                          icon: Iconsax.lock_1,
                          iconColor: AppColors.textSecondary,
                          title: 'Change Password',
                          subtitle: 'Send password reset email',
                          onTap: () => _handleChangePassword(context)),
                    ]),

                    // NOTIFICATIONS section
                    _sectionLabel('NOTIFICATIONS'),
                    _settingsCard([
                      _switchItem(context,
                          icon: Iconsax.notification,
                          iconColor: AppColors.accentOrange,
                          title: 'Push Notifications',
                          subtitle: 'Receive push notifications',
                          value: settings.notificationsEnabled,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setNotificationsEnabled(v)),
                      _switchItem(context,
                          icon: Iconsax.sms,
                          iconColor: AppColors.primary,
                          title: 'Email Notifications',
                          subtitle: 'Receive email updates',
                          value: settings.emailNotificationsEnabled,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setEmailNotificationsEnabled(v)),
                      _switchItem(context,
                          icon: Iconsax.briefcase,
                          iconColor: AppColors.accentTeal,
                          title: 'Campaign Updates',
                          subtitle: 'New campaigns & deadlines',
                          value: true,
                          onChanged: (_) {}),
                    ]),

                    // PRIVACY section
                    _sectionLabel('PRIVACY'),
                    _settingsCard([
                      _switchItem(context,
                          icon: Iconsax.eye,
                          iconColor: AppColors.textSecondary,
                          title: 'Public Profile',
                          subtitle: 'Allow others to find your profile',
                          value: true,
                          onChanged: (_) {}),
                    ]),

                    // SUPPORT section
                    _sectionLabel('SUPPORT'),
                    _settingsCard([
                      _item(context,
                          icon: Iconsax.message_question,
                          iconColor: AppColors.accentTeal,
                          title: 'Help & Support',
                          subtitle: 'FAQs and contact',
                          onTap: () => context.push('/help-support')),
                      _item(context,
                          icon: Iconsax.shield_tick,
                          iconColor: AppColors.textHint,
                          title: 'Privacy Policy',
                          onTap: () => context.push('/privacy-policy')),
                      _item(context,
                          icon: Iconsax.document_text,
                          iconColor: AppColors.textHint,
                          title: 'Terms of Service',
                          onTap: () => context.push('/terms-of-service')),
                      _item(context,
                          icon: Iconsax.info_circle,
                          iconColor: AppColors.textHint,
                          title: 'About Rexo',
                          subtitle: 'Version 1.0.0',
                          onTap: () => _showAbout(context)),
                    ]),

                    // ACCOUNT ACTIONS (danger)
                    _sectionLabel('ACCOUNT ACTIONS',
                        color: AppColors.error.withOpacity(0.7)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.allLg,
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _handleLogout(context, ref),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.lg)),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.logout,
                                          color: AppColors.error, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Log Out',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(
                                height: 1,
                                color: AppColors.divider),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _handleDeleteAccount(context),
                                borderRadius: const BorderRadius.vertical(
                                    bottom:
                                        Radius.circular(AppRadius.lg)),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      Icon(Iconsax.trash,
                                          color: AppColors.error, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Delete Account',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, ProfileState profileState) {
    final profile = profileState.profile;
    if (profile == null) return const SizedBox(height: AppSpacing.lg);

    final name = profile['name'] ?? 'User';
    final handle = profile['handle'] ?? '';
    final role = profile['role'] ?? 'creator';
    final avatarUrl = profile['avatar_url'];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            PremiumAvatar(
              imageUrl: avatarUrl,
              name: name,
              size: 56,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: AppRadius.pillAll,
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen()),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textHint,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Rexo',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.allMd,
        ),
        child: const Icon(Iconsax.crown_1, color: Colors.white, size: 28),
      ),
      children: [
        const Text(
          'Rexo — a premium influencer marketing platform connecting brands '
          'and creators for campaigns, collaborations and payouts.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
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
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone.\n\n'
          'Please contact support at support@rexo.app to complete account deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// AppMotion stub kept for import compatibility
class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 300);
  static const double pressScale = 0.97;
  static const Curve standard = Curves.easeOutCubic;
}
