import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../moderation/screens/moderation_screen.dart';
import 'campaign_control_screen.dart';
import 'disputes_screen.dart';
import 'fraud_review_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_jobs_screen.dart';
import 'push_broadcast_screen.dart';
import 'review_job_submissions_screen.dart';
import 'rexo_program_screen.dart';
import 'submission_review_screen.dart';
import 'wallets_escrow_screen.dart';
import 'withdrawal_queue_screen.dart';

/// Admin Center → Actions hub.
///
/// Old layout: a hand-built header (a gradient rounded square beside two
/// stacked `Text`s), then four sections whose tiles were `Material` + `InkWell`
/// + `Container` stacks that each redeclared their own 16px radius, hairline
/// border, tinted icon square and label style — and which hardcoded
/// `Colors.white`, so they would not follow the canvas.
///
/// New layout: the standard collapsing large title, and every tile now comes
/// from the shared [GlassTileGrid] / [GlassTile] pair. The grouping (Finance /
/// Content / Reviews / Safety & Comms) and all navigation targets are
/// unchanged.
class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          const GlassLargeTitleHeader(
            title: 'Admin actions',
            subtitle: 'Manage platform operations',
          ),

          _section(context, 'Finance', [
            _ActionItem(
              icon: AppIcons.money_send,
              label: 'Withdrawal queue',
              color: AppColors.accentPurple,
              screen: () => const WithdrawalQueueScreen(),
            ),
            _ActionItem(
              icon: AppIcons.wallet,
              label: 'Wallets & escrow',
              color: AppColors.accentBrown,
              screen: () => const WalletsEscrowScreen(),
            ),
          ]),

          _section(context, 'Content', [
            _ActionItem(
              icon: AppIcons.image,
              label: 'Manage banners',
              color: AppColors.accentIndigo,
              screen: () => const ManageBannersScreen(),
            ),
            _ActionItem(
              icon: AppIcons.briefcase,
              label: 'Campaign control',
              color: AppColors.primary,
              screen: () => const CampaignControlScreen(),
            ),
            _ActionItem(
              icon: AppIcons.task_square,
              label: 'Manage jobs',
              color: AppColors.accentTeal,
              screen: () => const ManageJobsScreen(),
            ),
          ]),

          _section(context, 'Reviews', [
            _ActionItem(
              icon: AppIcons.document_upload,
              label: 'Submissions',
              color: AppColors.success,
              screen: () => const SubmissionReviewScreen(),
            ),
            _ActionItem(
              icon: AppIcons.document_text,
              label: 'Job submissions',
              color: AppColors.accentOrange,
              screen: () => const ReviewJobSubmissionsScreen(),
            ),
            _ActionItem(
              icon: AppIcons.message_question,
              label: 'Disputes',
              color: AppColors.error,
              screen: () => const DisputesScreen(),
            ),
            _ActionItem(
              icon: AppIcons.award,
              label: 'Program review',
              color: AppColors.accentAmber,
              screen: () => const RexoProgramScreen(),
            ),
          ]),

          _section(context, 'Safety & comms', [
            _ActionItem(
              icon: AppIcons.shield_cross,
              label: 'Risk & fraud',
              color: AppColors.error,
              screen: () => const FraudReviewScreen(),
            ),
            _ActionItem(
              icon: AppIcons.flag,
              label: 'Reports',
              color: AppColors.accentOrange,
              screen: () => const ModerationScreen(),
            ),
            _ActionItem(
              icon: AppIcons.message_text,
              label: 'Support inbox',
              color: AppColors.primary,
              route: '/messages',
            ),
            _ActionItem(
              icon: AppIcons.notification,
              label: 'Push broadcast',
              color: AppColors.accentPink,
              screen: () => const PushBroadcastScreen(),
            ),
          ]),

          // Clearance for the floating admin dock.
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  /// One labelled group of destination tiles.
  Widget _section(
    BuildContext context,
    String title,
    List<_ActionItem> items,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.xs,
                AppSpacing.md,
              ),
              child: Text(
                title.toUpperCase(),
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            GlassTileGrid(
              columns: 2,
              tiles: [
                for (final item in items)
                  GlassTile(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    onTap: () => item.open(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A destination in the actions hub: either a pushed screen or a named route.
class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;

  /// Built lazily so the screen is only constructed when actually opened.
  final Widget Function()? screen;
  final String? route;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.screen,
    this.route,
  });

  void open(BuildContext context) {
    if (route != null) {
      context.push(route!);
    } else if (screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen!()),
      );
    }
  }
}
