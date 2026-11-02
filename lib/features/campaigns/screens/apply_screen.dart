import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/campaigns_provider.dart';

/// Apply to a campaign — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over one run of nine field blocks, each built
/// by a local `_buildField` helper that printed its own bold `Text` label above
/// a `PremiumTextField`; the campaign context was a hand-decorated tinted
/// `Container`; the load failure was a bare icon, `Text` and `TextButton`; the
/// submit button sat at the end of a long scroll; and success opened an
/// `AlertDialog`.
///
/// New layout: a collapsing large title; the campaign being applied to shown
/// as a brand card; the form split into four named groups (about you, where
/// you are, contact & reach, your pitch) so it reads as four short steps;
/// labels from the shared field instead of a local helper; city/state paired
/// side by side; and submit pinned so it is reachable at any scroll offset.
/// Success is now a glass dialog.
///
/// `campaignDetailProvider`, `applyPrefillProfileProvider`, the prefill rule,
/// `campaignActionsProvider.applyToCampaign` with every named argument, the
/// `hasAppliedProvider` invalidation and all nine validators are unchanged.
class ApplyScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const ApplyScreen({
    super.key,
    required this.campaignId,
  });

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _contactController = TextEditingController();
  final _instagramController = TextEditingController();
  final _followersController = TextEditingController();
  final _pitchController = TextEditingController();
  final _portfolioUrlController = TextEditingController();

  bool _isSubmitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactController.dispose();
    _instagramController.dispose();
    _followersController.dispose();
    _pitchController.dispose();
    _portfolioUrlController.dispose();
    super.dispose();
  }

  /// Prefill Name / Instagram from the signed-in user's profile the first time
  /// the profile becomes available.
  void _maybePrefill(Map<String, dynamic>? profile) {
    if (_prefilled || profile == null) return;
    _prefilled = true;
    final name = (profile['name'] ?? '').toString();
    if (name.isNotEmpty && _nameController.text.isEmpty) {
      _nameController.text = name;
    }
    final handle = (profile['username'] ?? '').toString(); // live: username
    if (handle.isNotEmpty && _instagramController.text.isEmpty) {
      _instagramController.text = handle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignAsync = ref.watch(campaignDetailProvider(widget.campaignId));

    // Prefill from the current user's profile when it loads.
    ref.listen(applyPrefillProfileProvider, (_, next) {
      next.whenData(_maybePrefill);
    });
    _maybePrefill(ref.watch(applyPrefillProfileProvider).valueOrNull);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                GlassLargeTitleHeader(
                  title: 'Apply',
                  subtitle: 'Tell the brand why you fit',
                  showBack: true,
                  onBack: () => context.pop(),
                ),

                // Which campaign this is for.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: campaignAsync.when(
                      data: (campaign) {
                        if (campaign == null) return const SizedBox.shrink();
                        return GlassCard.brand(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const GlassIconBubble(
                                icon: AppIcons.briefcase,
                                size: 36,
                                iconSize: 18,
                              ),
                              AppSpacing.gapMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Applying to',
                                      style: AppTextStyles.caption1.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (campaign['title'] ?? 'Campaign')
                                          .toString(),
                                      style: AppTextStyles.headline.copyWith(
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const GlassCard(
                        child: Row(
                          children: [
                            GlassSkeleton(width: 36, height: 36),
                            SizedBox(width: AppSpacing.md),
                            Expanded(child: GlassSkeleton(height: 16)),
                          ],
                        ),
                      ),
                      error: (error, _) => GlassErrorState(
                        title: 'Failed to load campaign',
                        compact: true,
                        onRetry: () => ref.invalidate(
                          campaignDetailProvider(widget.campaignId),
                        ),
                      ),
                    ),
                  ),
                ),

                // 1 — About you
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('About you'),
                        GlassTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Your full name',
                          prefixIcon: AppIcons.user,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _categoryController,
                          label: 'Category / niche',
                          hint: 'e.g. Fashion, Tech, Fitness',
                          prefixIcon: AppIcons.category,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your category'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2 — Where you are
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Where you are'),
                        GlassTextField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'Country / region',
                          prefixIcon: AppIcons.location,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your location'
                              : null,
                        ),
                        AppSpacing.gapLg,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GlassTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'City',
                                prefixIcon: AppIcons.building,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter city'
                                        : null,
                              ),
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: GlassTextField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'State',
                                prefixIcon: AppIcons.map,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter state'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3 — Contact & reach
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Contact & reach'),
                        GlassTextField(
                          controller: _contactController,
                          label: 'Contact number',
                          hint: '10-digit mobile number',
                          prefixIcon: AppIcons.call,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s]'),
                            ),
                          ],
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) {
                              return 'Please enter your contact number';
                            }
                            final digits =
                                value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length < 7 || digits.length > 15) {
                              return 'Enter a valid contact number';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _instagramController,
                          label: 'Instagram profile',
                          hint: '@handle or https://instagram.com/handle',
                          prefixIcon: AppIcons.instagram,
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) {
                              return 'Please enter your Instagram profile';
                            }
                            // Accept either a bare handle or a full/instagram URL.
                            final handleOk = RegExp(r'^@?[A-Za-z0-9._]{1,30}$')
                                .hasMatch(value);
                            final uri = Uri.tryParse(value);
                            final urlOk = uri != null &&
                                uri.hasScheme &&
                                uri.hasAuthority;
                            if (!handleOk && !urlOk) {
                              return 'Enter a valid handle or profile link';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _followersController,
                          label: 'Followers',
                          hint: 'Total followers (number)',
                          prefixIcon: AppIcons.people,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) {
                              return 'Please enter your followers count';
                            }
                            final n = int.tryParse(value);
                            if (n == null || n < 0) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 4 — Your pitch
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Your pitch'),
                        GlassTextField.multiline(
                          controller: _pitchController,
                          label: 'Pitch',
                          hint:
                              'Tell the brand why you are the right fit for this campaign…',
                          helperText: 'At least 20 characters',
                          minLines: 5,
                          maxLines: 6,
                          maxLength: 500,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your pitch';
                            }
                            if (value.trim().length < 20) {
                              return 'Pitch should be at least 20 characters';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapLg,
                        GlassTextField(
                          controller: _portfolioUrlController,
                          label: 'Portfolio URL (optional)',
                          hint: 'https://your-portfolio.com',
                          prefixIcon: AppIcons.link,
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final uri = Uri.tryParse(value);
                              if (uri == null ||
                                  !uri.hasScheme ||
                                  !uri.hasAuthority) {
                                return 'Please enter a valid URL';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Clearance for the pinned action.
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Submit application',
              icon: AppIcons.send_2,
              size: GlassButtonSize.large,
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitApplication,
            ),
          ),
        ],
      ),
    );
  }

  /// Group heading matching the tracked-caps header used by `GlassSection`.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption1.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success =
        await ref.read(campaignActionsProvider.notifier).applyToCampaign(
              campaignId: widget.campaignId,
              pitch: _pitchController.text.trim(),
              portfolioUrl: _portfolioUrlController.text.trim(),
              applicantName: _nameController.text.trim(),
              location: _locationController.text.trim(),
              category: _categoryController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              contactNumber: _contactController.text.trim(),
              instagramUrl: _instagramController.text.trim(),
              followersCount: int.tryParse(_followersController.text.trim()),
            );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      // Invalidate the hasApplied provider
      ref.invalidate(hasAppliedProvider(widget.campaignId));

      await showGlassDialog(
        context: context,
        title: 'Application sent',
        message: 'Your application has been submitted successfully. '
            'The brand will review it and get back to you.',
        icon: AppIcons.tick_circle,
        iconColor: AppColors.success,
        confirmLabel: 'Done',
      );

      if (!mounted) return;
      context.pop();
    } else {
      final actionState = ref.read(campaignActionsProvider);
      final errorMsg = actionState.hasError
          ? ErrorUtils.sanitize(actionState.error)
          : 'Failed to submit application. Please try again.';
      showGlassSnackBar(
        context,
        message: errorMsg,
        tone: GlassToastTone.error,
      );
    }
  }
}
