import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: Text(
          'Security Logs',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                _buildFilterChip(context,
                  ref,
                  'All',
                  SecurityLogFilter.all,
                  activeFilter,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(context,
                  ref,
                  'Logins',
                  SecurityLogFilter.logins,
                  activeFilter,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(context,
                  ref,
                  'Suspicious',
                  SecurityLogFilter.suspicious,
                  activeFilter,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          // Logs list
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) => _buildLogItem(context, logs[index]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerLoading(height: 360),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load security logs',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref,
    String label,
    SecurityLogFilter filter,
    SecurityLogFilter activeFilter,) {
    final isActive = filter == activeFilter;

    return GestureDetector(
      onTap: () {
        ref.read(securityLogFilterProvider.notifier).state = filter;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
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

    final eventConfig = _getEventConfig(eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              eventConfig.icon,
              color: eventConfig.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventConfig.label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSuspicious)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
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
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'IP: $ipAddress',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (deviceInfo.toString().isNotEmpty)
                  Text(
                    deviceInfo.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  createdAt,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _EventConfig _getEventConfig(String eventType) {
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
        return _EventConfig(
          icon: Iconsax.lock,
          color: const Color(0xFF2196F3),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No security events',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your security log is clear',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
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
