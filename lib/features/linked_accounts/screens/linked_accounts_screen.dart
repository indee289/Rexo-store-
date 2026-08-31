import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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

class _LinkedAccountsScreenState
    extends ConsumerState<LinkedAccountsScreen> {
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
      backgroundColor: Colors.white,
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

  bool _isConnected(
      List<Map<String, dynamic>> accounts, String platform) {
    return accounts.any((a) =>
        a['platform'] == platform &&
        (a['handle'] ?? '').toString().isNotEmpty);
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> accounts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: AppRadius.allSm,
                  ),
                  child: const Icon(Iconsax.link_2,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect your social accounts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Link platforms to boost your campaign reach',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _platformCard(
            accounts: accounts,
            platform: 'instagram',
            displayName: 'Instagram',
            icon: Iconsax.instagram,
            color: AppColors.socialInstagram,
            hint: '@your_handle',
            controller: _instagramController,
          ),
          const SizedBox(height: AppSpacing.md),

          _platformCard(
            accounts: accounts,
            platform: 'youtube',
            displayName: 'YouTube',
            icon: Iconsax.video_play,
            color: AppColors.socialYoutube,
            hint: 'channel name',
            controller: _youtubeController,
          ),
          const SizedBox(height: AppSpacing.md),

          _platformCard(
            accounts: accounts,
            platform: 'tiktok',
            displayName: 'TikTok',
            icon: Iconsax.video_tick,
            color: AppColors.socialTiktok,
            hint: '@your_handle',
            controller: _tiktokController,
          ),
          const SizedBox(height: AppSpacing.md),

          _platformCard(
            accounts: accounts,
            platform: 'twitter',
            displayName: 'Twitter / X',
            icon: Iconsax.message_text,
            color: AppColors.socialTwitter,
            hint: '@your_handle',
            controller: _twitterController,
          ),
          const SizedBox(height: AppSpacing.md),

          _platformCard(
            accounts: accounts,
            platform: 'facebook',
            displayName: 'Facebook',
            icon: Iconsax.global,
            color: AppColors.socialFacebook,
            hint: 'page or profile name',
            controller: _facebookController,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Save button
          PremiumButton(
            label: _isSaving ? 'Saving...' : 'Save Changes',
            loading: _isSaving,
            onPressed: _isSaving ? null : () => _save(context, accounts),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _platformCard({
    required List<Map<String, dynamic>> accounts,
    required String platform,
    required String displayName,
    required IconData icon,
    required Color color,
    required String hint,
    required TextEditingController controller,
  }) {
    final connected = _isConnected(accounts, platform);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connected
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          connected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: connected
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
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
              size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text('Failed to load accounts',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(linkedAccountsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      BuildContext context, List<Map<String, dynamic>> accounts) async {
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(linkedAccountsActionsProvider.notifier);
      final platformHandles = {
        'instagram': _instagramController.text.trim(),
        'youtube': _youtubeController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'facebook': _facebookController.text.trim(),
      };
      for (final entry in platformHandles.entries) {
        if (entry.value.isNotEmpty) {
          await notifier.saveAccount(platform: entry.key, handle: entry.value);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accounts saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
