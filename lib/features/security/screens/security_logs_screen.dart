import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_chip.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/security_provider.dart';

class SecurityLogsScreen extends ConsumerWidget {
  const SecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(securityLogsProvider);
    final activeFilter = ref.watch(securityLogFilterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Security Logs', showBack: true),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                _buildFilterChip(
                    ref, 'All', SecurityLogFilter.all, activeFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(
                    ref, 'Logins', SecurityLogFilter.logins, activeFilter),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip(ref, 'Suspicious',
                    SecurityLogFilter.suspicious, activeFilter),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          // Logs list
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: logs.length,
                  itemBuilder: (context, index) =>
                      _buildLogItem(context, logs[index]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: ShimmerLoading(height: 360),
              ),
              error: (error, _) => const EmptyState(
                icon: Iconsax.warning_2,
                title: 'Failed to load security logs',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    WidgetRef ref,
    String label,
    SecurityLogFilter filter,
    SecurityLogFilter activeFilter,
  ) {
    return PremiumChip(
      label: label,
      selected: filter == activeFilter,
      onTap: () {
        ref.read(securityLogFilterProvider.notifier).state = filter;
      },
    );
  }

  Widget _buildLogItem(BuildContext context, Map<String, dynamic> log) {
    final eventType = log['event_type'] ?? 'unknown';
    final ipAddress = log['ip_address'] ?? 'Unknown IP';
    final deviceInfo = log['device_info'] ?? '';
    final isSuspicious = log['is_suspicious'] == true;
    final createdAt = log['created_at'] != null
        ? DateFormat('MMM dd, yyyy HH:mm')
            .format(DateTime.parse(log['created_at']))
        : 'Unknown';

    final eventConfig = _getEventConfig(context, eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: isSuspicious
              ? AppColors.error.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: eventConfig.color.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              eventConfig.icon,
              color: eventConfig.color,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventConfig.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSuspicious)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: AppRadius.allSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.warning_2,
                              color: AppColors.error,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Suspicious',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'IP: $ipAddress',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                if (deviceInfo.toString().isNotEmpty)
                  Text(
                    deviceInfo.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  createdAt,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _EventConfig _getEventConfig(BuildContext context, String eventType) {
    switch (eventType) {
      case 'login':
        return _EventConfig(
          icon: Iconsax.key,
          color: AppColors.success,
          label: 'Login',
        );
      case 'logout':
        return _EventConfig(
          icon: Iconsax.logout,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          label: 'Logout',
        );
      case 'failed_login':
        return _EventConfig(
          icon: Iconsax.close_circle,
          color: AppColors.error,
          label: 'Failed Login',
        );
      case 'password_change':
        return const _EventConfig(
          icon: Iconsax.lock,
          color: AppColors.roleBrand,
          label: 'Password Changed',
        );
      default:
        return _EventConfig(
          icon: Iconsax.shield_tick,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          label: eventType.replaceAll('_', ' ').toUpperCase(),
        );
    }
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Iconsax.shield_tick,
      title: 'No security events',
      subtitle: 'Your security log is clear',
    );
  }
}

class _EventConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _EventConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
