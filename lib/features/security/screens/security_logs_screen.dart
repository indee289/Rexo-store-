import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/security_provider.dart';

/// Security logs — rebuilt layout.
///
/// Old layout: `PremiumAppBar`, then a filter strip in an opaque `Container`
/// separated by a `Divider`, then a `ListView` of hand-built `Container` rows.
/// The filter strip scrolled away with nothing, and the divider was the only
/// thing separating it from the list.
///
/// New layout: the filter chips live in the header's pinned slot, so they stay
/// reachable while the log scrolls under them, and the divider is gone — the
/// header's own fill separates it. Entries are rows in one grouped section,
/// with suspicious events carrying a red chip.
///
/// `securityLogsProvider`, `securityLogFilterProvider` and the event mapping
/// are unchanged.
class SecurityLogsScreen extends ConsumerWidget {
  const SecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(securityLogsProvider);
    final activeFilter = ref.watch(securityLogFilterProvider);

    const filters = [
      SecurityLogFilter.all,
      SecurityLogFilter.logins,
      SecurityLogFilter.suspicious,
    ];
    const labels = ['All', 'Logins', 'Suspicious'];

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Security logs',
            showBack: true,
            bottomHeight: 56,
            bottom: GlassChipRow(
              labels: labels,
              selectedIndex: filters.indexOf(activeFilter),
              onSelected: (i) => ref
                  .read(securityLogFilterProvider.notifier)
                  .state = filters[i],
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.shield_tick,
                    title: 'No security events',
                    message: 'Your security log is clear.',
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: GlassSection(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    for (final log in logs) _LogRow(log: log),
                  ],
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
                title: 'Failed to load security logs',
                onRetry: () => ref.invalidate(securityLogsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final eventType = (log['event_type'] ?? 'unknown').toString();
    final ipAddress = (log['ip_address'] ?? 'Unknown IP').toString();
    final deviceInfo = (log['device_info'] ?? '').toString();
    final isSuspicious = log['is_suspicious'] == true;
    final createdAt = log['created_at'] != null
        ? DateFormat('MMM dd, yyyy HH:mm')
            .format(DateTime.parse(log['created_at']))
        : 'Unknown';

    final config = _eventConfig(eventType);

    final meta = [
      'IP: $ipAddress',
      if (deviceInfo.isNotEmpty) deviceInfo,
      createdAt,
    ].join('  ·  ');

    return GlassRow(
      icon: config.icon,
      iconColor: isSuspicious ? AppColors.error : config.color,
      title: config.label,
      subtitle: meta,
      showChevron: false,
      trailing: isSuspicious
          ? GlassChip.status(
              label: 'Suspicious',
              icon: AppIcons.warning_2,
              color: AppColors.error,
            )
          : null,
    );
  }

  static _EventConfig _eventConfig(String eventType) {
    switch (eventType) {
      case 'login':
        return const _EventConfig(
          icon: AppIcons.key,
          color: AppColors.success,
          label: 'Login',
        );
      case 'logout':
        return const _EventConfig(
          icon: AppIcons.logout,
          color: AppColors.textHint,
          label: 'Logout',
        );
      case 'failed_login':
        return const _EventConfig(
          icon: AppIcons.close_circle,
          color: AppColors.error,
          label: 'Failed login',
        );
      case 'password_change':
        return const _EventConfig(
          icon: AppIcons.lock,
          color: AppColors.warning,
          label: 'Password changed',
        );
      default:
        return _EventConfig(
          icon: AppIcons.shield_tick,
          color: AppColors.textSecondary,
          label: eventType
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w.isNotEmpty
                  ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
                  : w)
              .join(' '),
        );
    }
  }
}

class _EventConfig {
  const _EventConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}
