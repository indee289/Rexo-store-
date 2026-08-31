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
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/linked_accounts_provider.dart';

class LinkedAccountsScreen extends ConsumerStatefulWidget {
  const LinkedAccountsScreen({super.key});

  @override
  ConsumerState<LinkedAccountsScreen> createState() =>
      _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends ConsumerState<LinkedAccountsScreen> {
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  bool _isSaving = false;
  bool _populated = false;

  @override
  void dispose() {
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Linked Accounts',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (!_populated) {
            _populateControllers(accounts);
            _populated = true;
          }
          return _buildContent(context, accounts);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildError(context),
      ),
    );
  }

  void _populateControllers(List<Map<String, dynamic>> accounts) {
    for (final account in accounts) {
      final platform = account['platform'] as String?;
      final handle = account['handle'] as String? ?? '';
      switch (platform) {
        case 'instagram':
          if (_instagramController.text.isEmpty) {
            _instagramController.text = handle;
          }
          break;
        case 'youtube':
          if (_youtubeController.text.isEmpty) {
            _youtubeController.text = handle;
          }
          break;
        case 'tiktok':
          if (_tiktokController.text.isEmpty) {
            _tiktokController.text = handle;
          }
          break;
        case 'twitter':
          if (_twitterController.text.isEmpty) {
            _twitterController.text = handle;
          }
          break;
        case 'facebook':
          if (_facebookController.text.isEmpty) {
            _facebookController.text = handle;
          }
          break;
      }
    }
  }

  bool _isConnected(List<Map<String, dynamic>> accounts, String platform) {
    return accounts.any((a) =>
        a['platform'] == platform &&
        (a['handle'] ?? '').toString().isNotEmpty);
  }

  Map<String, dynamic>? _getAccount(
      List<Map<String, dynamic>> accounts, String platform) {
    try {
      return accounts.firstWhere((a) => a['platform'] == platform);
    } catch (_) {
      return null;
    }
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> accounts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header description
          _buildHeader(context),
          const SizedBox(height: AppSpacing.xl),

          // Platform cards grid
          Text(
            'Your Platforms',
            style: AppTextStyles.h6.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Instagram
          _buildPlatformCard(
            context,
            index: 0,
            accounts: accounts,
            platform: 'instagram',
            displayName: 'Instagram',
            icon: Iconsax.instagram,
            color: AppColors.socialInstagram,
            gradient: const LinearGradient(
              colors: [Color(0xFFE1306C), Color(0xFFF77737)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            hint: '@your_handle',
            controller: _instagramController,
            followers: '1.2M',
          ),
          const SizedBox(height: AppSpacing.md),

          // YouTube
          _buildPlatformCard(
            context,
            index: 1,
            accounts: accounts,
            platform: 'youtube',
            displayName: 'YouTube',
            icon: Iconsax.video_play,
            color: AppColors.socialYoutube,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            hint: 'Channel name or URL',
            controller: _youtubeController,
          ),
          const SizedBox(height: AppSpacing.md),

          // TikTok
          _buildPlatformCard(
            context,
            index: 2,
            accounts: accounts,
            platform: 'tiktok',
            displayName: 'TikTok',
            icon: Iconsax.music,
            color: AppColors.socialTiktok,
            gradient: const LinearGradient(
              colors: [Color(0xFF010101), Color(0xFF333333)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            hint: '@your_handle',
            controller: _tiktokController,
          ),
          const SizedBox(height: AppSpacing.md),

          // Twitter/X
          _buildPlatformCard(
            context,
            index: 3,
            accounts: accounts,
            platform: 'twitter',
            displayName: 'Twitter / X',
            icon: Iconsax.message,
            color: AppColors.socialTwitter,
            gradient: const LinearGradient(
              colors: [Color(0xFF1DA1F2), Color(0xFF0D8BD9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            hint: '@your_handle',
            controller: _twitterController,
          ),
          const SizedBox(height: AppSpacing.md),

          // Facebook
          _buildPlatformCard(
            context,
            index: 4,
            accounts: accounts,
            platform: 'facebook',
            displayName: 'Facebook',
            icon: Iconsax.global,
            color: AppColors.socialFacebook,
            gradient: const LinearGradient(
              colors: [Color(0xFF1877F2), Color(0xFF0C5FD1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            hint: 'Profile URL or name',
            controller: _facebookController,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Save button
          PremiumButton(
            label: 'Save All Accounts',
            icon: Iconsax.save_2,
            gradient: true,
            loading: _isSaving,
            onPressed: _isSaving ? null : () => _saveAccounts(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Summary stats row
          if (accounts.isNotEmpty) ...[
            _buildSummaryRow(context, accounts),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: const Icon(Iconsax.link_2,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Your Socials',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showcase your reach to brands and unlock higher-value campaigns.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: -0.05, end: 0, curve: AppMotion.standard);
  }

  Widget _buildPlatformCard(
    BuildContext context, {
    required int index,
    required List<Map<String, dynamic>> accounts,
    required String platform,
    required String displayName,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required String hint,
    required TextEditingController controller,
    String? followers,
  }) {
    final theme = Theme.of(context);
    final isConnected = _isConnected(accounts, platform);
    final account = _getAccount(accounts, platform);
    final isVerified = account?['verified'] == true;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allLg,
        border: Border.all(
          color: isConnected
              ? color.withOpacity(0.3)
              : theme.dividerColor,
          width: isConnected ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? color.withOpacity(0.08)
                : Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: isConnected ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Platform header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Platform icon with gradient background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: AppRadius.allMd,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(Iconsax.verify,
                                size: 14,
                                color: AppColors.success),
                          ],
                        ],
                      ),
                      if (isConnected &&
                          controller.text.isNotEmpty)
                        Text(
                          controller.text,
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Not connected',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4),
                          ),
                        ),
                    ],
                  ),
                ),
                // Status chip
                AnimatedContainer(
                  duration: AppMotion.base,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? color.withOpacity(0.1)
                        : theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(
                      color: isConnected
                          ? color.withOpacity(0.3)
                          : theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.success
                              : theme.colorScheme.onSurface
                                  .withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Connected' : 'Connect',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isConnected
                              ? AppColors.success
                              : theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Input field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? AppColors.darkSurfaceAlt
                    : AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.allMd,
                  borderSide:
                      BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allMd,
                  borderSide:
                      BorderSide(color: theme.dividerColor, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allMd,
                  borderSide:
                      BorderSide(color: color, width: 1.5),
                ),
                prefixIcon: Icon(icon, size: 16, color: color),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Iconsax.close_circle,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.4)),
                        onPressed: () {
                          controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          // Verification status (if connected)
          if (isConnected) ...[
            Divider(
                height: 1,
                color: color.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Iconsax.tick_circle
                        : Iconsax.clock,
                    size: 14,
                    color: isVerified
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isVerified
                        ? 'Account verified'
                        : 'Pending verification',
                    style: AppTextStyles.caption.copyWith(
                      color: isVerified
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: AppMotion.base)
        .slideX(begin: 0.02, end: 0, curve: AppMotion.standard);
  }

  Widget _buildSummaryRow(
      BuildContext context, List<Map<String, dynamic>> accounts) {
    final theme = Theme.of(context);
    final connected = accounts.length;
    final verified = accounts.where((a) => a['verified'] == true).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryStat(
              value: '$connected',
              label: 'Connected',
              color: AppColors.primary),
          Container(
              width: 1,
              height: 36,
              color: theme.dividerColor),
          _SummaryStat(
              value: '$verified',
              label: 'Verified',
              color: AppColors.success),
          Container(
              width: 1,
              height: 36,
              color: theme.dividerColor),
          _SummaryStat(
              value: '${5 - connected}',
              label: 'Pending',
              color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2,
              size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.lg),
          Text('Failed to load accounts',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => ref.invalidate(linkedAccountsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccounts(BuildContext context) async {
    setState(() => _isSaving = true);

    final notifier = ref.read(linkedAccountsActionsProvider.notifier);
    int saved = 0;

    final platformData = {
      'instagram': _instagramController.text.trim(),
      'youtube': _youtubeController.text.trim(),
      'tiktok': _tiktokController.text.trim(),
      'twitter': _twitterController.text.trim(),
      'facebook': _facebookController.text.trim(),
    };

    for (final entry in platformData.entries) {
      if (entry.value.isNotEmpty) {
        await notifier.saveAccount(
            platform: entry.key, handle: entry.value);
        saved++;
      }
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved > 0
                ? '$saved account${saved > 1 ? 's' : ''} saved successfully'
                : 'No accounts to save',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor:
              saved > 0 ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.allMd),
        ),
      );
    }
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h5.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
