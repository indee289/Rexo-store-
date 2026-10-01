import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../providers/referral_provider.dart';

/// "Refer & Earn" — share your code, see your stats, and redeem a friend's code.
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
    final result =
        await ref.read(referralActionsProvider.notifier).redeem(_codeController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? AppColors.success : AppColors.error,
      ),
    );
    if (result.ok) _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codeAsync = ref.watch(myReferralCodeProvider);
    final statsAsync = ref.watch(referralStatsProvider);
    final hasRedeemed = ref.watch(hasRedeemedReferralProvider).asData?.value ?? false;
    final isLoading = ref.watch(referralActionsProvider).isLoading;

    final code = codeAsync.asData?.value ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Refer & Earn',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0095F6), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.allLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.gift, color: Colors.white, size: 32),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Invite friends, earn rewards',
                    style: AppTextStyles.h5.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'You and your friend each earn reward points when they join '
                    'Kixo with your code.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Your code
            Text('Your referral code',
                style: AppTextStyles.labelLarge
                    .copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.allMd,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code.isEmpty ? '—' : code,
                      style: AppTextStyles.h6.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (code.isNotEmpty)
                    IconButton(
                      icon: const Icon(Iconsax.copy, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (code.isNotEmpty)
              PremiumButton(
                label: 'Share invite',
                icon: Iconsax.send_2,
                variant: PremiumButtonVariant.outline,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text:
                        'Join me on Kixo! Use my referral code "$code" when you '
                        'sign up and we both earn rewards.',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite message copied — paste it anywhere')),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xl),

            // Stats
            statsAsync.when(
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Friends referred',
                      value: s.referredCount.toString(),
                      icon: Iconsax.people,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatBox(
                      label: 'Reward points',
                      value: s.rewardPoints.toString(),
                      icon: Iconsax.medal_star,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                  height: 72, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Redeem a code
            Text('Have a referral code?',
                style: AppTextStyles.labelLarge
                    .copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            if (hasRedeemed)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text("You've already applied a referral code.")),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _codeController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: "Enter a friend's code",
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.allMd,
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumButton(
                label: 'Apply code',
                loading: isLoading,
                onPressed: isLoading ? null : _redeem,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTextStyles.h5
                  .copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700)),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
