import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';

final _rexoProgramProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('rexo_program_applications')
      .select()
      .order('applied_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

/// Admin Campster Program review — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over admin-local `PremiumCard`s, each with a
/// hand-built tinted icon square, the status rendered as plain grey body text,
/// and an `ElevatedButton`/`OutlinedButton` pair carrying inline `styleFrom`
/// colours. Empty and error states were stacked `Text`s.
///
/// New layout: a collapsing large title, cards on the shared surface with the
/// status as a colour-coded chip, a `GlassButton` pair for the decision, and
/// the shared glass states with pull-to-refresh and a retry.
///
/// The table, the ordering, the `status` writes and the `_rexoProgramProvider`
/// invalidation are unchanged. The two failure toasts now run through
/// `ErrorUtils.sanitize` like the rest of the app, instead of interpolating a
/// raw `e.toString()` into the message.
class RexoProgramScreen extends ConsumerWidget {
  const RexoProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(_rexoProgramProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(_rexoProgramProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GlassLargeTitleHeader(
              title: 'Program review',
              subtitle: 'Campster Program applications',
              showBack: true,
            ),
            applications.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.award,
                      title: 'No applications to review',
                      message: 'New applications will appear here.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => AppSpacing.gapMd,
                    itemBuilder: (context, index) => RepaintBoundary(
                      child: _ApplicationCard(
                        app: list[index],
                        onDecision: (status) => _decide(
                          context,
                          ref,
                          list[index]['id'],
                          status,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: GlassListSkeleton(itemCount: 5),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  message: ErrorUtils.sanitize(error),
                  onRetry: () => ref.invalidate(_rexoProgramProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Writes the decision. Same table, same column, same invalidation as before.
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    Object? id,
    String status,
  ) async {
    try {
      // `.eq` takes a non-nullable Object, so the id is checked before use
      // rather than force-unwrapped.
      if (id == null) return;
      await SupabaseService.client
          .from('rexo_program_applications')
          .update({'status': status}).eq('id', id);
      ref.invalidate(_rexoProgramProvider);
    } catch (e) {
      if (context.mounted) {
        showGlassSnackBar(
          context,
          message: ErrorUtils.sanitize(e),
          tone: GlassToastTone.error,
        );
      }
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final ValueChanged<String> onDecision;

  const _ApplicationCard({required this.app, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    final status = (app['status'] ?? 'pending').toString();
    final reason = app['reason'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassIconBubble(
                icon: AppIcons.award,
                color: AppColors.accentAmber,
                size: 36,
                iconSize: 18,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  (app['applicant_name'] ?? 'Applicant').toString(),
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(label: status, color: _statusColor(status)),
            ],
          ),
          if (reason != null) ...[
            AppSpacing.gapSm,
            Text(
              reason.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Approve',
                  icon: AppIcons.tick_circle,
                  size: GlassButtonSize.small,
                  onPressed: () => onDecision('approved'),
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.outline(
                  label: 'Reject',
                  icon: AppIcons.close_circle,
                  size: GlassButtonSize.small,
                  onPressed: () => onDecision('rejected'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}
