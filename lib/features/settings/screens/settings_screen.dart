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
  // ── Theme-aware color helpers ────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? AppColors.darkBackground : AppColors.background;
  Color get _cardBg => _isDark ? AppColors.darkCard : Colors.white;
  Color get _borderColor =>
      _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _dividerColor =>
      _isDark ? AppColors.darkDivider : AppColors.divider;
  Color get _textPrimary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _textSecondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _textHint => _isDark ? AppColors.darkTextHint : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: _pageBg,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.chevron_left,
                        size: 28, color: _textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
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

                    // APPEARANCE section
                    _sectionLabel('APPEARANCE'),
                    _settingsCard([
                      _appearanceItem(settings.themeMode),
                    ]),

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
                          iconColor: _textSecondary,
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
                          iconColor: _textSecondary,
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
                          iconColor: _textHint,
                          title: 'Privacy Policy',
                          onTap: () => context.push('/privacy-policy')),
                      _item(context,
                          icon: Iconsax.document_text,
                          iconColor: _textHint,
                          title: 'Terms of Service',
                          onTap: () => context.push('/terms-of-service')),
                      _item(context,
                          icon: Iconsax.info_circle,
                          iconColor: _textHint,
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
                          color: _cardBg,
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
                            Divider(height: 1, color: _dividerColor),
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
          color: _cardBg,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: _borderColor),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.primaryBg,
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
          color: color ?? _textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: _borderColor),
        ),
        child: Column(children: children),
      ),
    );
  }

  // ── Appearance (theme mode) selector ──────────────────────────────────────
  Widget _appearanceItem(ThemeMode mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: const Icon(Iconsax.moon,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Choose how Rexo looks',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _themeChoice('System', Iconsax.mobile, ThemeMode.system, mode),
              const SizedBox(width: 8),
              _themeChoice('Light', Iconsax.sun_1, ThemeMode.light, mode),
              const SizedBox(width: 8),
              _themeChoice('Dark', Iconsax.moon, ThemeMode.dark, mode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeChoice(
      String label, IconData icon, ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).setThemeMode(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (_isDark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.surfaceAlt),
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : _textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _textSecondary,
                ),
              ),
            ],
          ),
        ),
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
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: _dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _textHint,
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
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
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
