import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';

/// Audit logs — rebuilt layout.
///
/// Old layout: `PremiumAppBar` with a stock `IconButton` refresh over a
/// `ListView` of admin-local `PremiumCard`s, each a hand-built row with
/// hardcoded 13/11/10pt text, plus a bare centred column for the empty state
/// and a raw `Text` for errors.
///
/// New layout: collapsing large title with the entry count and a glass refresh
/// button, and the log as one grouped section of rows — an audit trail is a
/// list, and the old per-entry cards made 50 entries read as 50 objects.
///
/// `adminAuditLogsProvider` is unchanged.
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(adminAuditLogsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Audit logs',
            subtitle: logs.maybeWhen(
              data: (l) => l.isEmpty ? null : '${l.length} entries',
              orElse: () => null,
            ),
            actions: [
              GlassIconButton(
                icon: AppIcons.refresh,
                tooltip: 'Refresh',
                size: 36,
                iconSize: 18,
                onTap: () => ref.invalidate(adminAuditLogsProvider),
              ),
            ],
          ),
          logs.when(
            data: (list) {
              if (list.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassEmptyState(
                    icon: AppIcons.document_text,
                    title: 'No audit logs',
                    message: 'Admin actions will be recorded here.',
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: GlassSection(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
                  ),
                  children: [
                    for (final log in list) _LogRow(log: log),
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
                title: 'Failed to load audit logs',
                message: ErrorUtils.sanitize(error),
                onRetry: () => ref.invalidate(adminAuditLogsProvider),
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
    final createdAt = log['created_at'] != null
        ? DateFormat('MMM dd, yyyy HH:mm')
            .format(DateTime.parse(log['created_at']))
        : '';
    final reason = log['reason']?.toString();

    final subtitle = [
      if (reason != null && reason.isNotEmpty) reason,
      if (createdAt.isNotEmpty) createdAt,
    ].join('  ·  ');

    return GlassRow(
      icon: AppIcons.document_text,
      title: (log['action_type'] ?? 'Unknown action').toString(),
      subtitle: subtitle.isEmpty ? null : subtitle,
      showChevron: false,
    );
  }
}
