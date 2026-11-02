import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/coupons_provider.dart';

/// Coupons & rewards — rebuilt layout.
///
/// Old layout: `DefaultTabController` + a Material `TabBar` in the app bar's
/// bottom slot driving a `TabBarView`, with each tab rendering its own
/// `ListView` of hand-built `Container` cards.
///
/// New layout: collapsing large title with a segmented control in its pinned
/// slot, and the two tabs swapped through an `IndexedStack` — the underline
/// `TabBar` is replaced because an underline indicator is the weakest possible
/// selection cue, and a segmented control shows both options as equals.
///
/// `availableCouponsProvider` and `userRewardPointsProvider` are unchanged, as
/// is the fact that the Redeem button is not yet wired to an action.
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Coupons & rewards',
            showBack: true,
            bottomHeight: 62,
            bottom: GlassTabBar(
              labels: const ['Coupons', 'Rewards'],
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
          SliverToBoxAdapter(
            child: IndexedStack(
              index: _tab,
              // Both tabs stay alive, so switching back does not refetch.
              sizing: StackFit.loose,
              children: const [_CouponsTab(), _RewardsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponsTab extends ConsumerWidget {
  const _CouponsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(availableCouponsProvider);

    return couponsAsync.when(
      data: (coupons) {
        if (coupons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxl),
            child: GlassEmptyState(
              icon: AppIcons.ticket_discount,
              title: 'No coupons available',
              message: 'Check back later for new offers.',
              compact: true,
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: Column(
            children: [
              for (final c in coupons)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RepaintBoundary(child: _CouponCard(coupon: c)),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: GlassLoader(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: GlassErrorState(
          compact: true,
          title: 'Failed to load coupons',
          onRetry: () => ref.invalidate(availableCouponsProvider),
        ),
      ),
    );
  }
}

/// A coupon, laid out like a real voucher: the discount is the headline and the
/// code is a copy-ready recessed well, rather than both being body text.
class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});

  final Map<String, dynamic> coupon;

  @override
  Widget build(BuildContext context) {
    final code = coupon['code'] as String? ?? '';
    final discountType = coupon['discount_type'] as String? ?? 'fixed';
    final discountValue = (coupon['discount_value'] as num?)?.toDouble() ?? 0;
    final minOrder = (coupon['min_order'] as num?)?.toDouble() ?? 0;
    final expiresAt = coupon['expires_at'] as String?;

    final discountLabel = discountType == 'percentage'
        ? '${discountValue.toInt()}% off'
        : '\u20B9${discountValue.toStringAsFixed(0)} OFF';

    String expiryLabel = '';
    if (expiresAt != null) {
      final date = DateTime.tryParse(expiresAt);
      if (date != null) {
        expiryLabel = 'Expires ${DateFormat('dd MMM yyyy').format(date)}';
      }
    }

    return GlassCard(
      borderRadius: AppRadius.allLg,
      rim: AppColors.primaryRim,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassIconBubble(
                icon: AppIcons.ticket_discount,
                size: 40,
                iconSize: 20,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      discountLabel,
                      style: AppTextStyles.title2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Min. order \u20B9${minOrder.toStringAsFixed(0)}'
                      '${expiryLabel.isEmpty ? '' : '  ·  $expiryLabel'}',
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (code.isNotEmpty) ...[
            AppSpacing.gapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.allMd,
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardsTab extends ConsumerWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(userRewardPointsProvider);

    return rewardsAsync.when(
      data: (rewards) {
        final points = (rewards?['points'] as int?) ?? 0;
        final canRedeem = points >= 100;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassSurface(
                level: GlassLevel.card,
                borderRadius: AppRadius.allXl,
                gradient: AppColors.primaryGradient,
                bordered: false,
                shadow: AppElevation.brand(false),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Icon(
                      AppIcons.medal_star,
                      size: 34,
                      color: Colors.white,
                    ),
                    AppSpacing.gapMd,
                    Text(
                      '$points',
                      style: AppTextStyles.largeTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'REWARD POINTS',
                      style: AppTextStyles.caption1.copyWith(
                        color: Colors.white.withOpacity(0.78),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapXl,
              GlassCard(
                borderRadius: AppRadius.allLg,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Redeem points',
                      style: AppTextStyles.headline.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'Use your reward points for discounts on your next '
                      'purchase. 100 points = \u20B910 off.',
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    AppSpacing.gapLg,
                    GlassButton.outline(
                      label: canRedeem ? 'Redeem now' : 'Need 100+ points',
                      // Unchanged from before: redemption is not wired to an
                      // action yet, so this stays a no-op when enabled.
                      onPressed: canRedeem ? () {} : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: GlassLoader(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: GlassErrorState(
          compact: true,
          title: 'Failed to load rewards',
          onRetry: () => ref.invalidate(userRewardPointsProvider),
        ),
      ),
    );
  }
}
