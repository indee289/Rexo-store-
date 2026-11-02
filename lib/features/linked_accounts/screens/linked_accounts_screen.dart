import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/linked_accounts_provider.dart';

/// Linked accounts — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a column of five identical hand-built
/// `_platformCard` containers, each with its own `TextFormField` decoration and
/// a hand-drawn connected/not-connected dot, plus six local `isDark` colour
/// getters and a bespoke error screen with an outlined circle.
///
/// New layout: collapsing large title; the five platforms as one grouped
/// section where each row pairs the platform's real brand mark with its field,
/// so the list reads as one form rather than five cards; connected state shown
/// by a status chip; and the save action pinned.
///
/// Also switched TikTok, X and Facebook to their real brand marks — they
/// previously used a generic video-tick, a chat bubble and a globe.
///
/// `linkedAccountsProvider`, `linkedAccountsActionsProvider.saveAccount`, the
/// platform keys and the save loop are unchanged.
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

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              GlassLargeTitleHeader(
                title: 'Linked accounts',
                subtitle: 'Boost your campaign reach',
                showBack: true,
                onBack: () => context.pop(),
              ),
              accountsAsync.when(
                data: (accounts) {
                  if (!_populated) {
                    _populateControllers(accounts);
                    _populated = true;
                  }
                  return SliverToBoxAdapter(
                    child: GlassSection(
                      title: 'Platforms',
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        120,
                      ),
                      children: [
                        _PlatformRow(
                          displayName: 'Instagram',
                          icon: AppIcons.instagram,
                          color: AppColors.socialInstagram,
                          hint: '@your_handle',
                          controller: _instagramController,
                          connected: _isConnected(accounts, 'instagram'),
                        ),
                        _PlatformRow(
                          displayName: 'YouTube',
                          icon: AppIcons.youtube,
                          color: AppColors.socialYoutube,
                          hint: 'channel name',
                          controller: _youtubeController,
                          connected: _isConnected(accounts, 'youtube'),
                        ),
                        _PlatformRow(
                          displayName: 'TikTok',
                          icon: AppIcons.tiktok,
                          color: AppColors.socialTiktok,
                          hint: '@your_handle',
                          controller: _tiktokController,
                          connected: _isConnected(accounts, 'tiktok'),
                        ),
                        _PlatformRow(
                          displayName: 'Twitter / X',
                          icon: AppIcons.x,
                          color: AppColors.socialTwitter,
                          hint: '@your_handle',
                          controller: _twitterController,
                          connected: _isConnected(accounts, 'twitter'),
                        ),
                        _PlatformRow(
                          displayName: 'Facebook',
                          icon: AppIcons.facebook,
                          color: AppColors.socialFacebook,
                          hint: 'page or profile name',
                          controller: _facebookController,
                          connected: _isConnected(accounts, 'facebook'),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassLoader(),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassErrorState(
                    title: 'Could not load accounts',
                    message: 'Check your connection and try again.',
                    onRetry: () => ref.invalidate(linkedAccountsProvider),
                  ),
                ),
              ),
            ],
          ),

          if (accountsAsync.hasValue)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              child: GlassButton(
                label: 'Save changes',
                loading: _isSaving,
                size: GlassButtonSize.large,
                onPressed: _isSaving ? null : _save,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
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
        showGlassSnackBar(
          context,
          message: 'Accounts saved successfully',
          tone: GlassToastTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// One platform: brand mark, name, connected chip, and its handle field.
class _PlatformRow extends StatelessWidget {
  const _PlatformRow({
    required this.displayName,
    required this.icon,
    required this.color,
    required this.hint,
    required this.controller,
    required this.connected,
  });

  final String displayName;
  final IconData icon;
  final Color color;
  final String hint;
  final TextEditingController controller;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: AppRadius.allXs,
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Center(child: Icon(icon, size: 17, color: color)),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GlassChip.status(
                label: connected ? 'Connected' : 'Not connected',
                color: connected ? AppColors.success : AppColors.textHint,
              ),
            ],
          ),
          AppSpacing.gapSm,
          GlassTextField(
            controller: controller,
            hint: hint,
          ),
        ],
      ),
    );
  }
}
