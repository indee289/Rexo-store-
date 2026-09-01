import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _cs => Theme.of(context).colorScheme;
  Color get _cardBg => _isDark ? AppColors.darkCard : Colors.white;
  Color get _borderColor =>
      _isDark ? AppColors.darkBorder : AppColors.border;
  Color get _surfaceAlt =>
      _isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
  Color get _textHint => _isDark ? AppColors.darkTextHint : AppColors.textHint;

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
              color: AppColors.primary.withOpacity(_isDark ? 0.14 : 0.08),
              borderRadius: AppRadius.allLg,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.16),
                    borderRadius: AppRadius.allSm,
                  ),
                  child: const Icon(Iconsax.link_2,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect your social accounts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _cs.onSurface,
                        ),
                      ),
                      Text(
                        'Link platforms to boost your campaign reach',
                        style: TextStyle(
                          fontSize: 12,
                          color: _cs.onSurfaceVariant,
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
        color: _cardBg,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: _borderColor),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _cs.onSurface,
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
                                : _textHint,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          connected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            fontSize: 12,
                            color: connected
                                ? AppColors.success
                                : _textHint,
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
            style: TextStyle(fontSize: 14, color: _cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: _textHint),
              filled: true,
              fillColor: _surfaceAlt,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: BorderSide(color: color, width: 1.5),
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
          Icon(Iconsax.warning_2,
              size: 48, color: _cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Failed to load accounts',
              style: TextStyle(color: _cs.onSurfaceVariant)),
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
