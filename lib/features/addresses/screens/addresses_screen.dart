import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/addresses_provider.dart';

/// Saved addresses — rebuilt layout.
///
/// Old: `PremiumAppBar` over a `ListView` of hand-built `Container` cards, each
/// ending in a row of two `TextButton.icon`s, with a circular `FloatingActionButton`
/// and an `AlertDialog` for delete confirmation.
///
/// New: collapsing large title with the saved count, cards that carry the
/// default-address state on their own edge, actions as glass buttons, a
/// pill-shaped primary action pinned to the bottom instead of a floating
/// circle (a labelled pill says what it does), and a glass confirm for delete.
///
/// `addressesProvider`, `addressesActionsProvider.deleteAddress` and the
/// `/add-address` route (including the `extra` payload for edit) are unchanged.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              GlassLargeTitleHeader(
                title: 'My addresses',
                showBack: true,
                subtitle: addressesAsync.maybeWhen(
                  data: (list) => list.isEmpty
                      ? null
                      : '${list.length} saved',
                  orElse: () => null,
                ),
              ),
              addressesAsync.when(
                data: (addresses) {
                  if (addresses.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: GlassEmptyState(
                        icon: AppIcons.location,
                        title: 'No addresses saved',
                        message: 'Add your first address to get started.',
                        actionLabel: 'Add address',
                        onAction: () => context.push('/add-address'),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      96,
                    ),
                    sliver: SliverList.separated(
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => RepaintBoundary(
                        child: _AddressCard(address: addresses[index]),
                      ),
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
                    title: 'Failed to load addresses',
                    onRetry: () => ref.invalidate(addressesProvider),
                  ),
                ),
              ),
            ],
          ),
          // Pinned primary action. A labelled pill beats a bare circular FAB:
          // it names the action and gives a much larger target.
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Add address',
              icon: AppIcons.add,
              onPressed: () => context.push('/add-address'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final Map<String, dynamic> address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = address['name'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';
    final line1 = address['address_line1'] as String? ?? '';
    final line2 = address['address_line2'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final pincode = address['pincode'] as String? ?? '';
    final isDefault = address['is_default'] as bool? ?? false;
    final addressId = address['id'] as String;

    final fullAddress = [
      line1,
      if (line2.isNotEmpty) line2,
      '$city, $state - $pincode',
    ].join(', ');

    return GlassCard(
      borderRadius: AppRadius.allLg,
      // The default address carries a brand edge rather than needing a chip to
      // be read at a glance.
      rim: isDefault ? AppColors.primaryRim : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDefault)
                GlassChip.status(
                  label: 'Default',
                  color: AppColors.primary,
                ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: AppTextStyles.footnote
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            fullAddress,
            style: AppTextStyles.subheadline.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: GlassButton.glass(
                  label: 'Edit',
                  icon: AppIcons.edit_2,
                  size: GlassButtonSize.small,
                  onPressed: () =>
                      context.push('/add-address', extra: address),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.outline(
                  label: 'Delete',
                  icon: AppIcons.trash,
                  size: GlassButtonSize.small,
                  onPressed: () => _confirmDelete(context, ref, addressId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Delete address',
      message: 'Are you sure you want to delete this address?',
      icon: AppIcons.trash,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );

    if (confirmed) {
      await ref
          .read(addressesActionsProvider.notifier)
          .deleteAddress(addressId);
    }
  }
}
