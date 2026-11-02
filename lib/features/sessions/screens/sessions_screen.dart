import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/sessions_provider.dart';

/// Sessions & devices — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over two bare `Text` headings, each above a
/// column of hand-built `Container` cards; an `ElevatedButton.icon` styled red
/// at the bottom; and three more local helpers (`_buildEmptyState`,
/// `_buildErrorState`) each drawing their own bordered box. The terminate-all
/// confirmation was an `AlertDialog`.
///
/// New layout: collapsing large title; sessions and devices as two titled
/// sections of rows, each session's terminate action as an icon button on its
/// own row; and the destructive action in its own danger section with a glass
/// confirm.
///
/// `userSessionsProvider`, `userDevicesProvider`,
/// `sessionsNotifierProvider.terminateSession` and `terminateAllOtherSessions`
/// are unchanged.
class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(userSessionsProvider);
    final devicesAsync = ref.watch(userDevicesProvider);
    final sessionsState = ref.watch(sessionsNotifierProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Sessions & devices',
            showBack: true,
          ),

          // ── Active sessions ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: sessionsAsync.when(
              data: (sessions) => sessions.isEmpty
                  ? const _InfoSection(
                      title: 'Active sessions',
                      message: 'No active sessions',
                    )
                  : GlassSection(
                      title: 'Active sessions',
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: [
                        for (final s in sessions)
                          _SessionRow(session: s),
                      ],
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: GlassLoader(),
              ),
              error: (error, _) => _InfoSection(
                title: 'Active sessions',
                message: 'Failed to load sessions',
                isError: true,
                onRetry: () => ref.invalidate(userSessionsProvider),
              ),
            ),
          ),

          // ── Registered devices ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: devicesAsync.when(
              data: (devices) => devices.isEmpty
                  ? const _InfoSection(
                      title: 'My devices',
                      message: 'No registered devices',
                    )
                  : GlassSection(
                      title: 'My devices',
                      children: [
                        for (final d in devices) _DeviceRow(device: d),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (error, _) => _InfoSection(
                title: 'My devices',
                message: 'Failed to load devices',
                isError: true,
                onRetry: () => ref.invalidate(userDevicesProvider),
              ),
            ),
          ),

          // ── Destructive ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Danger zone',
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              children: [
                GlassRow(
                  icon: AppIcons.logout,
                  title: 'Log out all other sessions',
                  subtitle: 'Keeps only this device signed in',
                  destructive: true,
                  onTap: sessionsState.isLoading
                      ? null
                      : () => _confirmTerminateAll(context, ref),
                ),
                if (sessionsState.error != null)
                  GlassRow(
                    icon: AppIcons.warning_2,
                    title: sessionsState.error!,
                    destructive: true,
                    showChevron: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTerminateAll(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showGlassConfirm(
      context: context,
      title: 'Log out all sessions',
      message: 'This will terminate all sessions except your current one. '
          'Continue?',
      icon: AppIcons.logout,
      confirmLabel: 'Log out all',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (ok) {
      ref.read(sessionsNotifierProvider.notifier).terminateAllOtherSessions();
    }
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = (session['device_id'] ?? 'Unknown Device').toString();
    final ipAddress = (session['ip_address'] ?? 'Unknown IP').toString();
    final lastActive = session['last_active_at'] != null
        ? DateFormat('MMM dd, yyyy HH:mm')
            .format(DateTime.parse(session['last_active_at']))
        : 'Unknown';
    final sessionId = session['id'] as String;

    return GlassRow(
      icon: AppIcons.monitor,
      title: deviceId,
      subtitle: 'IP: $ipAddress  ·  Last active $lastActive',
      showChevron: false,
      trailing: GlassIconButton.bare(
        icon: AppIcons.close_circle,
        color: AppColors.error,
        size: 36,
        iconSize: 20,
        tooltip: 'Terminate session',
        onTap: () => ref
            .read(sessionsNotifierProvider.notifier)
            .terminateSession(sessionId),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device});

  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    final deviceName = (device['device_name'] ?? 'Unknown Device').toString();
    final deviceType = (device['device_type'] ?? 'unknown').toString();
    final osVersion = (device['os_version'] ?? '').toString();
    final appVersion = (device['app_version'] ?? '').toString();

    final icon = deviceType == 'desktop' ? AppIcons.monitor : AppIcons.mobile;

    final meta = [
      'Type: $deviceType',
      if (osVersion.isNotEmpty) 'OS: $osVersion',
      if (appVersion.isNotEmpty) 'App: $appVersion',
    ].join('  ·  ');

    return GlassRow(
      icon: icon,
      iconColor: AppColors.success,
      title: deviceName,
      subtitle: meta,
      showChevron: false,
    );
  }
}

/// Titled section showing a single informational or error message.
///
/// Replaces the two local helpers that each drew their own bordered box.
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String title;
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.textSecondary;

    return GlassSection(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                isError ? AppIcons.warning_2 : AppIcons.info_circle,
                size: 18,
                color: color,
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.subheadline.copyWith(color: color),
                ),
              ),
              if (onRetry != null)
                GlassButton.ghost(
                  label: 'Retry',
                  size: GlassButtonSize.small,
                  onPressed: onRetry,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
