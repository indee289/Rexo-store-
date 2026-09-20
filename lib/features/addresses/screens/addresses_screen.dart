import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/addresses_provider.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'My Addresses', showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-address'),
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return const EmptyState(
              icon: Iconsax.location,
              title: 'No addresses saved',
              subtitle: 'Add your first address to get started',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: addresses.length,
            itemBuilder: (context, index) =>
                _buildAddressCard(context, ref, addresses[index]),
          );
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load addresses',
          ctaLabel: 'Retry',
          ctaIcon: Iconsax.refresh,
          onCta: () => ref.invalidate(addressesProvider),
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> address,
  ) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: isDefault
              ? AppColors.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppRadius.allSm,
                  ),
                  child: Text(
                    'Default',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (phone.isNotEmpty)
            Text(
              phone,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            fullAddress,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/add-address', extra: address),
                icon: const Icon(Iconsax.edit_2, size: 16),
                label: Text('Edit', style: AppTextStyles.labelMedium),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref, addressId),
                icon: const Icon(Iconsax.trash, size: 16),
                label: Text('Delete', style: AppTextStyles.labelMedium),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete address', style: AppTextStyles.h6),
        content: Text(
          'Are you sure you want to delete this address?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(addressesActionsProvider.notifier)
          .deleteAddress(addressId);
    }
  }
}
