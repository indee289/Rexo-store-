import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_text_field.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Rate Calculator', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.allLg,
              ),
              child: Column(
                children: [
                  const Icon(
                    Iconsax.calculator,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Calculate Your Rate',
                    style: AppTextStyles.h5.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Find out the ideal rate per post based on your audience',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Inputs
            Text('Followers Count', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.sm),
            PremiumTextField(
              controller: _followersController,
              hint: 'e.g., 50000',
              prefixIcon: Iconsax.people,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Engagement Rate (%)', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.sm),
            PremiumTextField(
              controller: _engagementController,
              hint: 'e.g., 3.5',
              prefixIcon: Iconsax.chart_1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              suffix: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Text('%', style: AppTextStyles.bodyMedium),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Calculate button
            PremiumButton(
              label: 'Calculate',
              gradient: true,
              icon: Iconsax.calculator,
              onPressed: _calculate,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Result
            if (_suggestedRate != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: AppRadius.allLg,
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Suggested Rate Per Post',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '\u20B9${_suggestedRate!.toStringAsFixed(0)}',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Based on followers x engagement x 0.05 formula',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
