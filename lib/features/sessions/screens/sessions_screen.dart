import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/sessions_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userSessionsProvider);
    final devicesAsync = ref.watch(userDevicesProvider);
    final sessionsState = ref.watch(sessionsNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Sessions & Devices', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Sessions Section
            Text('Active Sessions', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.md),
            sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return _buildEmptyState(context, 'No active sessions');
                }
                return Column(
                  children: sessions
                      .map(
                          (session) => _buildSessionCard(context, ref, session))
                      .toList(),
                );
              },
              loading: () => const ShimmerLoading(height: 240),
              error: (error, _) => _buildErrorState('Failed to load sessions'),
            ),
            const SizedBox(height: AppSpacing.xl),
            // My Devices Section
            Text('My Devices', style: AppTextStyles.h6),
            const SizedBox(height: AppSpacing.md),
            devicesAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return _buildEmptyState(context, 'No registered devices');
                }
                return Column(
                  children: devices
                      .map((device) => _buildDeviceCard(context, device))
                      .toList(),
                );
              },
              loading: () => const ShimmerLoading(height: 160),
              error: (error, _) => _buildErrorState('Failed to load devices'),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Logout All Other Sessions Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sessionsState.isLoading
                    ? null
                    : () => _showTerminateAllDialog(context, ref),
                icon: const Icon(Iconsax.logout, size: 20),
                label: Text(
                  'Logout All Other Sessions',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.allMd,
                  ),
                ),
              ),
            ),
            if (sessionsState.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                sessionsState.error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> session,
  ) {
    final deviceId = session['device_id'] ?? 'Unknown Device';
    final ipAddress = session['ip_address'] ?? 'Unknown IP';
    final lastActive = session['last_active_at'] != null
        ? DateFormat('MMM dd, yyyy HH:mm')
            .format(DateTime.parse(session['last_active_at']))
        : 'Unknown';
    final sessionId = session['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: const Icon(
              Iconsax.monitor,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceId,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IP: $ipAddress',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                Text(
                  'Last active: $lastActive',
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
          IconButton(
            onPressed: () {
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .terminateSession(sessionId);
            },
            icon: const Icon(
              Iconsax.close_circle,
              color: AppColors.error,
              size: 22,
            ),
            tooltip: 'Terminate session',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, Map<String, dynamic> device) {
    final deviceName = device['device_name'] ?? 'Unknown Device';
    final deviceType = device['device_type'] ?? 'unknown';
    final osVersion = device['os_version'] ?? '';
    final appVersion = device['app_version'] ?? '';

    IconData deviceIcon;
    switch (deviceType) {
      case 'mobile':
        deviceIcon = Iconsax.mobile;
        break;
      case 'tablet':
        deviceIcon = Iconsax.mobile;
        break;
      case 'desktop':
        deviceIcon = Iconsax.monitor;
        break;
      default:
        deviceIcon = Iconsax.mobile;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(
              deviceIcon,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Type: $deviceType | OS: $osVersion',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                if (appVersion.isNotEmpty)
                  Text(
                    'App Version: $appVersion',
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

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.info_circle,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showTerminateAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout All Sessions', style: AppTextStyles.h6),
        content: Text(
          'This will terminate all sessions except your current one. Continue?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .terminateAllOtherSessions();
            },
            child: Text(
              'Logout All',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
