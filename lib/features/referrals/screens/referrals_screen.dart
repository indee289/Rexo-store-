import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/referral_provider.dart';

/// "Refer & Earn" — share your code, see your stats, and redeem a friend's code.
///
/// Old layout: `PremiumAppBar` over a flat `ListView` of bare `Text` labels
/// above hand-built `Container`s — a gradient hero, a code box with a stock
/// `IconButton`, two `_StatBox` containers, and a raw `TextField`.
///
/// New layout: collapsing large title; the referral code promoted to a
/// brand-filled card where the code itself is the hero (it is what the user
/// came for) with copy and share directly on it; stats as glass pills; and the
/// redeem form in its own section.
///
/// All four referral providers and the share/clipboard fallbacks are unchanged.
class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final result = await ref
        .read(referralActionsProvider.notifier)
        .redeem(_codeController.text);
    if (!mounted) return;
    showGlassSnackBar(
      context,
      message: result.message,
      tone: result.ok ? GlassToastTone.success : GlassToastTone.error,
    );
    if (result.ok) _codeController.clear();
  }

  Future<void> _share(String code) async {
    final message =
        'Join me on Campster! Use my referral code "$code" when you '
        'sign up and we both earn rewards.';
    try {
      await Share.share(message);
    } catch (_) {
      // Fallback to clipboard if share sheet fails
      await Clipboard.setData(ClipboardData(text: message));
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Invite message copied — paste it anywhere',
        tone: GlassToastTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeAsync = ref.watch(myReferralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);
    final hasRedeemed =
        ref.watch(hasRedeemedReferralProvider).asData?.value ?? false;
    final isLoading = ref.watch(referralActionsProvider).isLoading;

    final code = codeAsync.asData?.value ?? '';

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Refer & earn',
            subtitle: 'Invite friends, earn rewards',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // Code card — the code is the point of the screen.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: GlassSurface(
                level: GlassLevel.card,
                borderRadius: AppRadius.allXl,
                gradient: AppColors.primaryGradient,
                bordered: false,
                shadow: AppElevation.brand(false),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Icon(AppIcons.gift, color: Colors.white, size: 30),
                    AppSpacing.gapMd,
                    Text(
                      'YOUR REFERRAL CODE',
                      style: AppTextStyles.caption1.copyWith(
                        color: Colors.white.withOpacity(0.78),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    AppSpacing.gapSm,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        code.isEmpty ? '—' : code,
                        style: AppTextStyles.largeTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      AppSpacing.gapLg,
                      Row(
                        children: [
                          Expanded(
                            child: GlassButton.glass(
                              label: 'Copy',
                              icon: AppIcons.copy,
                              size: GlassButtonSize.small,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                showGlassSnackBar(
                                  context,
                                  message: 'Code copied',
                                  tone: GlassToastTone.success,
                                );
                              },
                            ),
                          ),
                          AppSpacing.gapSm,
                          Expanded(
                            child: GlassButton.glass(
                              label: 'Share',
                              icon: AppIcons.send_2,
                              size: GlassButtonSize.small,
                              onPressed: () => _share(code),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Stats.
          SliverToBoxAdapter(
            child: statsAsync.when(
              data: (s) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassStatPill(
                        icon: AppIcons.people,
                        value: s.referredCount.toString(),
                        label: 'Friends referred',
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: GlassStatPill(
                        icon: AppIcons.medal_star,
                        value: s.rewardPoints.toString(),
                        label: 'Reward points',
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: GlassLoader(size: 24),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Redeem.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              child: hasRedeemed
                  ? GlassCard(
                      borderRadius: AppRadius.allLg,
                      rim: AppColors.success.withOpacity(0.28),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          const GlassIconBubble(
                            icon: AppIcons.tick_circle,
                            color: AppColors.success,
                            size: 34,
                            iconSize: 17,
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Text(
                              "You've already applied a referral code.",
                              style: AppTextStyles.subheadline
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassTextField(
                          controller: _codeController,
                          label: 'Have a referral code?',
                          hint: "Enter a friend's code",
                          prefixIcon: AppIcons.ticket_discount,
                          enabled: !isLoading,
                        ),
                        AppSpacing.gapMd,
                        GlassButton(
                          label: 'Apply code',
                          loading: isLoading,
                          size: GlassButtonSize.large,
                          onPressed: isLoading ? null : _redeem,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
