import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';

/// Rate calculator — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a column of bare `Text` headings, each
/// followed by a `PremiumTextField`, with a full-bleed brand-gradient header
/// block at the top and a green-tinted result `Container` appended at the
/// bottom.
///
/// New layout: collapsing large title; the inputs grouped into one section so
/// the two fields read as a single form; and the result promoted to a brand
/// card that animates in, since it is the entire point of the screen.
///
/// The formula — followers x (engagement / 100) x 0.05 — is unchanged.
class RateCalculatorScreen extends StatefulWidget {
  const RateCalculatorScreen({super.key});

  @override
  State<RateCalculatorScreen> createState() => _RateCalculatorScreenState();
}

class _RateCalculatorScreenState extends State<RateCalculatorScreen> {
  final _followersController = TextEditingController();
  final _engagementController = TextEditingController();
  double? _suggestedRate;

  @override
  void dispose() {
    _followersController.dispose();
    _engagementController.dispose();
    super.dispose();
  }

  void _calculate() {
    final followers =
        double.tryParse(_followersController.text.replaceAll(',', ''));
    final engagement = double.tryParse(_engagementController.text);

    if (followers != null && engagement != null && followers > 0) {
      setState(() {
        _suggestedRate = followers * (engagement / 100) * 0.05;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Rate calculator',
            subtitle: 'Find your ideal rate per post',
            showBack: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassTextField(
                    controller: _followersController,
                    label: 'Followers count',
                    hint: 'e.g. 50000',
                    prefixIcon: AppIcons.people,
                    keyboardType: TextInputType.number,
                  ),
                  AppSpacing.gapLg,
                  GlassTextField(
                    controller: _engagementController,
                    label: 'Engagement rate',
                    hint: 'e.g. 3.5',
                    prefixIcon: AppIcons.chart_1,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: Text(
                        '%',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  GlassButton(
                    label: 'Calculate',
                    icon: AppIcons.calculator,
                    size: GlassButtonSize.large,
                    onPressed: _calculate,
                  ),
                  AppSpacing.gapXl,

                  // The result is the payload of this screen, so it gets the
                  // brand fill rather than a tinted side-note box.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _suggestedRate == null
                        ? const SizedBox(width: double.infinity)
                        : _ResultCard(rate: _suggestedRate!),
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.card,
      borderRadius: AppRadius.allXl,
      gradient: AppColors.primaryGradient,
      bordered: false,
      shadow: AppElevation.brand(false),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'SUGGESTED RATE PER POST',
            style: AppTextStyles.caption1.copyWith(
              color: Colors.white.withOpacity(0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            '\u20B9${rate.toStringAsFixed(0)}',
            style: AppTextStyles.largeTitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 40,
              letterSpacing: -1,
            ),
          ),
          AppSpacing.gapMd,
          Text(
            'Based on followers \u00D7 engagement \u00D7 0.05',
            textAlign: TextAlign.center,
            style: AppTextStyles.footnote.copyWith(
              color: Colors.white.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}
