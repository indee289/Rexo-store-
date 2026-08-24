import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_text_field.dart';
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
  bool _isSaving = false;

  @override
  void dispose() {
    _instagramController.dispose();
    _youtubeController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Linked Accounts', style: AppTextStyles.h5),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: PremiumIconButton(
            icon: Iconsax.arrow_left,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          _populateControllers(accounts);
          return _buildContent(accounts);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load linked accounts',
          ctaLabel: 'Retry',
          ctaIcon: Iconsax.refresh,
          onCta: () => ref.invalidate(linkedAccountsProvider),
        ),
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
      }
    }
  }

  Widget _buildContent(List<Map<String, dynamic>> accounts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your social media accounts to showcase your reach and engagement to brands.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildPlatformField(
            label: 'Instagram',
            controller: _instagramController,
            icon: Iconsax.instagram,
            hint: '@your_handle',
            color: AppColors.socialInstagram,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPlatformField(
            label: 'YouTube',
            controller: _youtubeController,
            icon: Iconsax.video_play,
            hint: 'Channel name or URL',
            color: AppColors.socialYoutube,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPlatformField(
            label: 'TikTok',
            controller: _tiktokController,
            icon: Iconsax.music,
            hint: '@your_handle',
            color: AppColors.socialTiktok,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PremiumButton(
            label: 'Save Accounts',
            gradient: true,
            loading: _isSaving,
            onPressed: _isSaving ? null : _saveAccounts,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Show verified status
          if (accounts.isNotEmpty) ...[
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Account Status',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...accounts.map((account) => _buildAccountStatus(account)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        PremiumTextField(
          controller: controller,
          hint: hint,
        ),
      ],
    );
  }

  Widget _buildAccountStatus(Map<String, dynamic> account) {
    final platform = account['platform'] as String? ?? '';
    final verified = account['verified'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            verified ? Iconsax.tick_circle : Iconsax.clock,
            size: 16,
            color: verified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            platform[0].toUpperCase() + platform.substring(1),
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: verified
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: Text(
              verified ? 'Verified' : 'Pending',
              style: AppTextStyles.labelSmall.copyWith(
                color: verified ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAccounts() async {
    setState(() => _isSaving = true);

    final notifier = ref.read(linkedAccountsActionsProvider.notifier);

    // Save each non-empty field
    if (_instagramController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'instagram',
        handle: _instagramController.text.trim(),
      );
    }
    if (_youtubeController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'youtube',
        handle: _youtubeController.text.trim(),
      );
    }
    if (_tiktokController.text.trim().isNotEmpty) {
      await notifier.saveAccount(
        platform: 'tiktok',
        handle: _tiktokController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Accounts saved successfully',
            style: AppTextStyles.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
