import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/premium_card.dart';
import 'campaign_control_screen.dart';
import 'deposit_queue_screen.dart';
import 'disputes_screen.dart';
import 'kyc_verification_screen.dart';
import 'push_broadcast_screen.dart';
import 'rexo_program_screen.dart';
import 'manage_jobs_screen.dart';
import 'review_job_submissions_screen.dart';
import 'submission_review_screen.dart';
import 'subscription_requests_screen.dart';
import 'wallets_escrow_screen.dart';
import 'withdrawal_queue_screen.dart';

class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Actions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage platform operations',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Iconsax.briefcase,
              title: 'Campaign Control',
              subtitle: 'Pause, resume, or cancel campaigns',
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CampaignControlScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.document_upload,
              title: 'Submission Review',
              subtitle: 'Approve or reject pending submissions',
              color: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubmissionReviewScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.money_recive,
              title: 'Deposit Queue',
              subtitle: 'Process pending deposits',
              color: AppColors.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DepositQueueScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.crown_1,
              title: 'Subscription Requests',
              subtitle: 'Approve or reject subscription payments',
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionRequestsScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.money_send,
              title: 'Withdrawal Queue',
              subtitle: 'Process pending withdrawals',
              color: AppColors.accentPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WithdrawalQueueScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.briefcase,
              title: 'Manage Jobs',
              subtitle: 'Post, edit, close and delete jobs',
              color: AppColors.accentTeal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageJobsScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.task_square,
              title: 'Review Job Submissions',
              subtitle: 'Approve or reject submitted tasks',
              color: AppColors.accentOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReviewJobSubmissionsScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.message_question,
              title: 'Disputes',
              subtitle: 'Investigate and resolve disputes',
              color: AppColors.error,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisputesScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.document,
              title: 'KYC Verification',
              subtitle: 'Verify identity documents',
              color: AppColors.accentIndigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const KycVerificationScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.wallet,
              title: 'Wallets & Escrow',
              subtitle: 'Manage wallets and escrow',
              color: AppColors.accentBrown,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WalletsEscrowScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.notification,
              title: 'Push Broadcast',
              subtitle: 'Send notifications to users',
              color: AppColors.accentPink,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PushBroadcastScreen()),
              ),
            ),
            _ActionTile(
              icon: Iconsax.award,
              title: 'Rexo Program Review',
              subtitle: 'Review program applications',
              color: AppColors.accentAmber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RexoProgramScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
