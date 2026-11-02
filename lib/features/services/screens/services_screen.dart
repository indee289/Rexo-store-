import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/services_provider.dart';

/// Creator services — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a `GridView.count` of two tall
/// `PremiumCard` tiles, then a bare `Text` heading above a column of listing
/// cards, each with a hand-built type badge. Tapping a listing opened a raw
/// `showModalBottomSheet` that drew its own grab handle.
///
/// New layout: collapsing large title; the two tools as a labelled tile grid;
/// the marketplace as a proper titled section of rows carrying the price as
/// trailing detail; and the detail as a glass sheet.
///
/// `activeServicesProvider`, the `take(10)` cap and both tool routes are
/// unchanged.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(activeServicesProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Creator services',
            showBack: true,
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Tools',
              separated: false,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                GlassTileGrid(
                  columns: 2,
                  tiles: [
                    GlassTile(
                      icon: AppIcons.document_text,
                      label: 'Media kit',
                      badge: 'Generate your kit',
                      color: AppColors.accentPurple,
                      onTap: () => context.push('/services/media-kit'),
                    ),
                    GlassTile(
                      icon: AppIcons.calculator,
                      label: 'Rate calculator',
                      badge: 'Find your rate',
                      color: AppColors.success,
                      onTap: () => context.push('/services/rate-calculator'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          servicesAsync.when(
            data: (services) {
              if (services.isEmpty) {
                return const SliverToBoxAdapter(
                  child: GlassEmptyState(
                    icon: AppIcons.shop,
                    title: 'No services listed yet',
                    message: 'Creator listings will appear here.',
                    compact: true,
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: GlassSection(
                  title: 'UGC marketplace',
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
                  ),
                  children: [
                    for (final s in services.take(10))
                      _ServiceRow(service: s),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: GlassLoader(),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: GlassErrorState(
                compact: true,
                title: 'Failed to load services',
                onRetry: () => ref.invalidate(activeServicesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final Map<String, dynamic> service;

  @override
  Widget build(BuildContext context) {
    final title = service['title'] as String? ?? 'Service';
    final description = service['description'] as String? ?? '';
    final price = (service['price'] as num?)?.toDouble() ?? 0.0;
    final serviceType = service['service_type'] as String? ?? '';

    final subtitle = [
      if (serviceType.isNotEmpty) serviceType,
      if (description.isNotEmpty) description,
    ].join('  ·  ');

    return GlassRow(
      icon: AppIcons.briefcase,
      title: title,
      subtitle: subtitle.isEmpty ? null : subtitle,
      trailingText: '\u20B9${price.toStringAsFixed(0)}',
      onTap: () => _showDetail(context),
    );
  }

  void _showDetail(BuildContext context) {
    final title = service['title'] as String? ?? 'Service';
    final description = service['description'] as String? ?? '';
    final price = (service['price'] as num?)?.toDouble() ?? 0.0;
    final serviceType = service['service_type'] as String? ?? '';

    showGlassSheet<void>(
      context: context,
      title: title,
      subtitle: serviceType.isEmpty ? null : serviceType,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            AppSpacing.gapLg,
          ],
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.allMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price',
                  style: AppTextStyles.callout
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '\u20B9${price.toStringAsFixed(0)}',
                  style: AppTextStyles.title2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
