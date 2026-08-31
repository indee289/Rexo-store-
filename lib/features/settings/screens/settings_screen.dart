import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom dark header ──────────────────────────────────────────
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: AppRadius.allSm,
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left,
                        size: 18,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // balance
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User card
                    profileAsync.whenOrNull(
                      data: (profileState) =>
                          _buildUserCard(context, profileState),
                    ) ?? const SizedBox(height: AppSpacing.lg),

                    // Search bar
                    _buildSearchBar(),

                    // Settings sections
                    if (_searchQuery.isEmpty) ...[
                      _buildSection(
                        context,
                        title: 'APPEARANCE',
                        icon: Iconsax.brush_2,
                        iconColor: AppColors.accentPurple,
                        children: [
                          _buildThemeSelector(context, ref, settings),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'ACCOUNT',
                        icon: Iconsax.user,
                        iconColor: AppColors.primary,
                        children: [
                          _buildItem(
                            context,
                            icon: Iconsax.edit,
                            iconColor: AppColors.primary,
                            title: 'Edit Profile',
                            subtitle: 'Update name, photo, bio',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen()),
                            ),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.link_2,
                            iconColor: AppColors.accentTeal,
                            title: 'Linked Accounts',
                            subtitle: 'Instagram, YouTube, TikTok',
                            onTap: () => context.push('/linked-accounts'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.verify,
                            iconColor: AppColors.success,
                            title: 'KYC Verification',
                            subtitle: 'Verify your identity',
                            onTap: () => context.push('/kyc'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.crown_1,
                            iconColor: AppColors.accentAmber,
                            title: 'Rexo Program',
                            subtitle: 'Apply to sell on marketplace',
                            onTap: () => _showRexoProgramInfo(context),
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'SECURITY',
                        icon: Iconsax.shield_tick,
                        iconColor: AppColors.accentIndigo,
                        children: [
                          _buildItem(
                            context,
                            icon: Iconsax.mobile,
                            iconColor: AppColors.accentIndigo,
                            title: 'Sessions & Devices',
                            subtitle: 'Manage active sessions',
                            onTap: () => context.push('/sessions'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.shield_tick,
                            iconColor: AppColors.success,
                            title: 'Two-Factor Authentication',
                            subtitle: 'Secure your account with TOTP',
                            trailing: _buildStatusBadge(
                                'Recommended', AppColors.success),
                            onTap: () => context.push('/two-factor-auth'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.lock_1,
                            iconColor: AppColors.warning,
                            title: 'Change Password',
                            subtitle: 'Send password reset email',
                            onTap: () => _handleChangePassword(context),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.document_text,
                            iconColor: AppColors.error,
                            title: 'Security Logs',
                            subtitle: 'View account activity',
                            onTap: () => context.push('/security-logs'),
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'NOTIFICATIONS',
                        icon: Iconsax.notification,
                        iconColor: AppColors.accentOrange,
                        children: [
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.notification,
                            iconColor: AppColors.accentOrange,
                            title: 'Push Notifications',
                            subtitle: 'Receive push notifications',
                            value: settings.notificationsEnabled,
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setNotificationsEnabled(v),
                          ),
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.sms,
                            iconColor: AppColors.primary,
                            title: 'Email Notifications',
                            subtitle: 'Receive email updates',
                            value: settings.emailNotificationsEnabled,
                            onChanged: (v) => ref
                                .read(settingsProvider.notifier)
                                .setEmailNotificationsEnabled(v),
                          ),
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.briefcase,
                            iconColor: AppColors.accentTeal,
                            title: 'Campaign Updates',
                            subtitle: 'New campaigns & deadlines',
                            value: true,
                            onChanged: (_) {},
                          ),
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.wallet_1,
                            iconColor: AppColors.success,
                            title: 'Wallet Alerts',
                            subtitle: 'Deposits & withdrawals',
                            value: true,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'PRIVACY',
                        icon: Iconsax.eye_slash,
                        iconColor: AppColors.neutral,
                        children: [
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.eye,
                            iconColor: AppColors.neutral,
                            title: 'Public Profile',
                            subtitle: 'Allow others to find your profile',
                            value: true,
                            onChanged: (_) {},
                          ),
                          _buildSwitchItem(
                            context,
                            icon: Iconsax.chart_square,
                            iconColor: AppColors.accentIndigo,
                            title: 'Analytics Sharing',
                            subtitle: 'Share anonymised usage data',
                            value: false,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                      _buildSection(
                        context,
                        title: 'SUPPORT',
                        icon: Iconsax.message_question,
                        iconColor: AppColors.accentTeal,
                        children: [
                          _buildItem(
                            context,
                            icon: Iconsax.message_question,
                            iconColor: AppColors.accentTeal,
                            title: 'Help & Support',
                            subtitle: 'FAQs and contact',
                            onTap: () => context.push('/help-support'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.shield_tick,
                            iconColor: AppColors.darkTextSecondary,
                            title: 'Privacy Policy',
                            onTap: () => context.push('/privacy-policy'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.document_text,
                            iconColor: AppColors.darkTextSecondary,
                            title: 'Terms of Service',
                            onTap: () => context.push('/terms-of-service'),
                          ),
                          _buildItem(
                            context,
                            icon: Iconsax.info_circle,
                            iconColor: AppColors.darkTextSecondary,
                            title: 'About Rexo',
                            subtitle: 'Version 1.0.0',
                            onTap: () => _showAbout(context),
                          ),
                        ],
                      ),
                      _buildDangerZone(context, ref),
                    ] else
                      _buildFilteredResults(context, ref, settings),

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

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.allLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: avatarUrl,
            name: name,
            size: 56,
            showRing: true,
            ringColor: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h6.copyWith(color: Colors.white),
                ),
                if (handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            icon: const Icon(Iconsax.edit, color: Colors.white, size: 20),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: -0.1, end: 0, curve: AppMotion.standard);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search settings...',
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.darkTextHint),
          filled: true,
          fillColor: AppColors.darkCard,
          prefixIcon: const Icon(
            Iconsax.search_normal,
            color: AppColors.darkTextSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle,
                      size: 18, color: AppColors.darkTextSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: AppRadius.allMd,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.allMd,
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.allMd,
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppColors.darkBorder, width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildItem(
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
        borderRadius: AppRadius.allMd,
        splashColor: AppColors.primary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: AppColors.darkTextHint,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.darkTextSecondary,
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

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Theme',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                _buildThemeOption(context, ref,
                    label: 'Light',
                    icon: Iconsax.sun_1,
                    mode: ThemeMode.light,
                    isSelected: settings.themeMode == ThemeMode.light),
                _buildThemeOption(context, ref,
                    label: 'Dark',
                    icon: Iconsax.moon,
                    mode: ThemeMode.dark,
                    isSelected: settings.themeMode == ThemeMode.dark),
                _buildThemeOption(context, ref,
                    label: 'System',
                    icon: Iconsax.mobile,
                    mode: ThemeMode.system,
                    isSelected: settings.themeMode == ThemeMode.system),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
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
                    : AppColors.darkTextHint,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkTextHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: const Icon(Iconsax.warning_2,
                    size: 14, color: AppColors.error),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'DANGER ZONE',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppRadius.allLg,
            border: Border.all(
                color: AppColors.error.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              _buildItem(
                context,
                icon: Iconsax.logout,
                iconColor: AppColors.error,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () => _handleLogout(context, ref),
              ),
              Divider(
                  height: 1, color: AppColors.error.withOpacity(0.1)),
              _buildItem(
                context,
                icon: Iconsax.trash,
                iconColor: AppColors.error,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account',
                onTap: () => _handleDeleteAccount(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredResults(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    final allItems = [
      ('Edit Profile', Iconsax.edit, AppColors.primary,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
      ('Linked Accounts', Iconsax.link_2, AppColors.accentTeal,
          () => context.push('/linked-accounts')),
      ('KYC Verification', Iconsax.verify, AppColors.success,
          () => context.push('/kyc')),
      ('Two-Factor Authentication', Iconsax.shield_tick, AppColors.success,
          () => context.push('/two-factor-auth')),
      ('Sessions & Devices', Iconsax.mobile, AppColors.accentIndigo,
          () => context.push('/sessions')),
      ('Change Password', Iconsax.lock_1, AppColors.warning,
          () => _handleChangePassword(context)),
      ('Privacy Policy', Iconsax.shield_tick, AppColors.darkTextSecondary,
          () => context.push('/privacy-policy')),
      ('Terms of Service', Iconsax.document_text, AppColors.darkTextSecondary,
          () => context.push('/terms-of-service')),
      ('Help & Support', Iconsax.message_question, AppColors.accentTeal,
          () => context.push('/help-support')),
      ('About Rexo', Iconsax.info_circle, AppColors.darkTextSecondary,
          () => _showAbout(context)),
    ];

    final filtered = allItems
        .where((item) => item.$1.toLowerCase().contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Column(
            children: [
              const Icon(Iconsax.search_normal,
                  size: 48, color: AppColors.darkTextHint),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No results for "$_searchQuery"',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppRadius.allLg,
          border: Border.all(color: AppColors.darkBorder, width: 1),
        ),
        child: Column(
          children: filtered
              .map((item) => _buildItem(
                    context,
                    icon: item.$2,
                    iconColor: item.$3,
                    title: item.$1,
                    onTap: item.$4,
                  ))
              .toList(),
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
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.allMd,
        ),
        child: const Icon(Iconsax.crown_1, color: Colors.white, size: 28),
      ),
      children: [
        Text(
          'Rexo — a premium influencer marketing platform connecting brands and '
          'creators for campaigns, collaborations and payouts.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '© 2024 Rexo. All rights reserved.',
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  void _showRexoProgramInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withOpacity(0.15),
                borderRadius: AppRadius.allSm,
              ),
              child: const Icon(Iconsax.crown_1,
                  color: AppColors.accentAmber, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Rexo Program', style: AppTextStyles.h6),
          ],
        ),
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
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary),
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
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Iconsax.logout, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text('Logout', style: AppTextStyles.h6),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Logout',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
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
        title: Row(
          children: [
            const Icon(Iconsax.trash, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text('Delete Account', style: AppTextStyles.h6),
          ],
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be deleted.\n\n'
          'Please contact support at support@rexo.app to complete account deletion.',
          style: AppTextStyles.bodyMedium,
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
