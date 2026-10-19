import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import 'campaign_control_screen.dart';
import 'fraud_review_screen.dart';
import 'disputes_screen.dart';
import 'push_broadcast_screen.dart';
import 'rexo_program_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_jobs_screen.dart';
import 'review_job_submissions_screen.dart';
import 'submission_review_screen.dart';
import 'wallets_escrow_screen.dart';
import 'withdrawal_queue_screen.dart';

/// Admin Center → Actions hub.
///
/// Redesigned into clean, grouped sections (Finance / Content / Reviews /
/// Safety & Comms) with a compact two-column tile grid. Navigation targets and
/// all backend/logic are unchanged — this is a UI-only redesign.
class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentIndigo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.setting_2,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: cs.onSurface,
                          )),
                      Text('Manage platform operations',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.55),
                          )),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  children: [
                    _Section(
                      title: 'Finance',
                      tiles: [
                        _Tile(
                          icon: Iconsax.money_send,
                          label: 'Withdrawal Queue',
                          color: AppColors.accentPurple,
                          screen: const WithdrawalQueueScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.wallet,
                          label: 'Wallets & Escrow',
                          color: AppColors.accentBrown,
                          screen: const WalletsEscrowScreen(),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Content',
                      tiles: [
                        _Tile(
                          icon: Iconsax.image,
                          label: 'Manage Banners',
                          color: AppColors.accentIndigo,
                          screen: const ManageBannersScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.briefcase,
                          label: 'Campaign Control',
                          color: AppColors.primary,
                          screen: const CampaignControlScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.task_square,
                          label: 'Manage Jobs',
                          color: AppColors.accentTeal,
                          screen: const ManageJobsScreen(),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Reviews',
                      tiles: [
                        _Tile(
                          icon: Iconsax.document_upload,
                          label: 'Submissions',
                          color: AppColors.success,
                          screen: const SubmissionReviewScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.document_text,
                          label: 'Job Submissions',
                          color: AppColors.accentOrange,
                          screen: const ReviewJobSubmissionsScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.message_question,
                          label: 'Disputes',
                          color: AppColors.error,
                          screen: const DisputesScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.award,
                          label: 'Program Review',
                          color: AppColors.accentAmber,
                          screen: const RexoProgramScreen(),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Safety & Comms',
                      tiles: [
                        _Tile(
                          icon: Iconsax.shield_cross,
                          label: 'Risk & Fraud',
                          color: AppColors.error,
                          screen: const FraudReviewScreen(),
                        ),
                        _Tile(
                          icon: Iconsax.notification,
                          label: 'Push Broadcast',
                          color: AppColors.accentPink,
                          screen: const PushBroadcastScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Tile> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            const spacing = 10.0;
            final w = (c.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tiles
                  .map((t) => SizedBox(width: w, child: t))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;

  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
