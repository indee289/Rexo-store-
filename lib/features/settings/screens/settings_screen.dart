import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../providers/settings_provider.dart';

/// Settings screen — rewritten from scratch.
///
/// Layout matches the reference UI:
/// - App bar with centered "Profile" title
/// - Dark header card with user info + "Upgrade to Pro" banner
/// - Grouped sections with white/glass card backgrounds
/// - Each item has icon + title + chevron
/// - Switches for toggles
/// - Red logout/delete section at bottom
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          children: [
            // ── App bar ──
            _AppBar(onBack: () => context.pop()),

            // ── Dark user header card ──
            profileAsync.whenOrNull(
                  data: (ps) => _UserHeaderCard(
                    profile: ps.profile,
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ) ??
                const SizedBox(height: 16),

            // ── Upgrade banner ──
            _UpgradeBanner(onTap: () => context.push('/subscriptions')),

            const SizedBox(height: 20),

            // ── ACCOUNT section ──
            _SectionTitle('ACCOUNT'),
            _GroupCard(children: [
              _SettingsItem(
                icon: Iconsax.edit,
                title: 'Edit Profile',
                subtitle: 'Update name, photo, bio',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                ),
              ),
              _SettingsItem(
                icon: Iconsax.link_2,
                title: 'Linked Accounts',
                subtitle: 'Instagram, YouTube, TikTok',
                onTap: () => context.push('/linked-accounts'),
              ),
              _SettingsItem(
                icon: Iconsax.verify,
                title: 'KYC Verification',
                subtitle: 'Verify your identity',
                onTap: () => context.push('/kyc'),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECURITY section ──
            _SectionTitle('SECURITY'),
            _GroupCard(children: [
              _SettingsItem(
                icon: Iconsax.shield_tick,
                title: 'Two-Factor Auth',
                subtitle: 'Secure your account with TOTP',
                trailing: _RecommendedBadge(),
                onTap: () => context.push('/settings/two-factor'),
              ),
              _SettingsItem(
                icon: Iconsax.monitor,
                title: 'Active Sessions',
                subtitle: 'Manage active sessions',
                onTap: () => context.push('/sessions'),
              ),
              _SettingsItem(
                icon: Iconsax.eye,
                title: 'Security Logs',
                subtitle: 'View account activity',
                onTap: () => context.push('/security-logs'),
              ),
              _SettingsItem(
                icon: Iconsax.lock,
                title: 'Change Password',
                subtitle: 'Send password reset email',
                onTap: () => _handleChangePassword(context),
              ),
            ]),

            const SizedBox(height: 20),

            // ── NOTIFICATIONS section ──
            _SectionTitle('NOTIFICATIONS'),
            _GroupCard(children: [
              _ToggleItem(
                icon: Iconsax.notification,
                title: 'Push Notifications',
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setNotificationsEnabled(v),
              ),
              _ToggleItem(
                icon: Iconsax.sms,
                title: 'Email Notifications',
                value: settings.emailNotificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setEmailNotificationsEnabled(v),
              ),
              _ToggleItem(
                icon: Iconsax.send_2,
                title: 'Campaign Updates',
                value: settings.campaignUpdatesEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setCampaignUpdatesEnabled(v),
              ),
            ]),

            const SizedBox(height: 20),

            // ── PRIVACY section ──
            _SectionTitle('PRIVACY'),
            _GroupCard(children: [
              _ToggleItem(
                icon: Iconsax.user,
                title: 'Public Profile',
                value: settings.publicProfileEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setPublicProfileEnabled(v),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SUPPORT section ──
            _SectionTitle('SUPPORT'),
            _GroupCard(children: [
              _SettingsItem(
                icon: Iconsax.message_question,
                title: 'Help & Support',
                subtitle: 'FAQs and contact',
                onTap: () => context.push('/help-support'),
              ),
              _SettingsItem(
                icon: Iconsax.shield_tick,
                title: 'Privacy Policy',
                onTap: () => context.push('/privacy-policy'),
              ),
              _SettingsItem(
                icon: Iconsax.document_text,
                title: 'Terms of Service',
                onTap: () => context.push('/terms-of-service'),
              ),
            ]),

            const SizedBox(height: 24),

            // ── Logout + Delete ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _DangerButton(
                    icon: Iconsax.logout,
                    label: 'Log Out',
                    onTap: () => _handleLogout(context, ref),
                  ),
                  const SizedBox(height: 10),
                  _DangerButton(
                    icon: Iconsax.trash,
                    label: 'Delete Account',
                    onTap: () => _handleDeleteAccount(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Actions ──

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
            content: Text('Failed to send reset email.'),
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
          'This action is permanent.\n\n'
          'Contact support@rexo.app to complete deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _AppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Iconsax.arrow_left, size: 24),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DARK USER HEADER CARD (like reference)
// ═══════════════════════════════════════════════════════════════════════════════

class _UserHeaderCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onEdit;

  const _UserHeaderCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox(height: 16);

    final name = (profile!['name'] ?? 'User').toString();
    final email = (profile!['email'] ?? '').toString();
    final avatarUrl = profile!['profileImage'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              PremiumAvatar(imageUrl: avatarUrl, name: name, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3,
                  size: 18, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPGRADE BANNER (dark card with CTA)
// ═══════════════════════════════════════════════════════════════════════════════

class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0095F6), Color(0xFF5856D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.crown_1, size: 28, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan & Subscription',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your subscription plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppRadius.pillAll,
                ),
                child: const Text(
                  'View ›',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: AppTextStyles.footnote.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GROUP CARD (frosted glass container for a section)
// ═══════════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: AppColors.border,
                      ),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS ITEM (icon + title + subtitle + chevron)
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(Iconsax.arrow_right_3,
                    size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOGGLE ITEM (icon + title + switch)
// ═══════════════════════════════════════════════════════════════════════════════

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECOMMENDED BADGE
// ═══════════════════════════════════════════════════════════════════════════════

class _RecommendedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.1),
        borderRadius: AppRadius.pillAll,
      ),
      child: const Text(
        'Recommended',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.accentGreen,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DANGER BUTTON (logout / delete)
// ═══════════════════════════════════════════════════════════════════════════════

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.error),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
