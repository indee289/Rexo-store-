import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';

/// One titled block of a legal document.
class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

/// Shared layout for the Privacy Policy and Terms of Service screens.
///
/// Both screens previously repeated the same structure: a `PremiumAppBar`, a
/// faint "Last updated" line, then a `SingleChildScrollView` of bare
/// heading-plus-paragraph pairs with no separation other than vertical
/// padding. On a long legal document that reads as an undifferentiated wall of
/// text.
///
/// This extracts the structure once and gives each section its own card, so a
/// reader can find and skim a clause. The collapsing large title also keeps the
/// document name visible while scrolling, which the old bar did not.
class LegalDocument extends StatelessWidget {
  const LegalDocument({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(title: title, showBack: true),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GlassChip.status(
                  label: 'Updated $lastUpdated',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: sections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => RepaintBoundary(
                child: _SectionCard(
                  index: i + 1,
                  section: sections[i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.index, required this.section});

  final int index;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.allLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered marker, so a clause can be referred to.
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: AppRadius.allXs,
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    section.title,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            section.body,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
