import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';

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
              onTap: () => context.push('/actions/campaigns'),
            ),
            _ActionTile(
              icon: Iconsax.document_upload,
              title: 'Submission Review',
              subtitle: 'Approve or reject pending submissions',
              color: AppColors.success,
              onTap: () => context.push('/actions/submissions'),
            ),
            _ActionTile(
              icon: Iconsax.money_recive,
              title: 'Deposit Queue',
              subtitle: 'Process pending deposits',
              color: AppColors.warning,
              onTap: () => context.push('/actions/deposits'),
            ),
            _ActionTile(
              icon: Iconsax.money_send,
              title: 'Withdrawal Queue',
              subtitle: 'Process pending withdrawals',
              color: Colors.purple,
              onTap: () => context.push('/actions/withdrawals'),
            ),
            _ActionTile(
              icon: Iconsax.shop,
              title: 'Shop Admin',
              subtitle: 'Manage products and orders',
              color: Colors.teal,
              onTap: () => context.push('/actions/shop'),
            ),
            _ActionTile(
              icon: Iconsax.message_question,
              title: 'Disputes',
              subtitle: 'Investigate and resolve disputes',
              color: AppColors.error,
              onTap: () => context.push('/actions/disputes'),
            ),
            _ActionTile(
              icon: Iconsax.document,
              title: 'KYC Verification',
              subtitle: 'Verify identity documents',
              color: Colors.indigo,
              onTap: () => context.push('/actions/kyc'),
            ),
            _ActionTile(
              icon: Iconsax.wallet,
              title: 'Wallets & Escrow',
              subtitle: 'Manage wallets and escrow',
              color: Colors.brown,
              onTap: () => context.push('/actions/wallets'),
            ),
            _ActionTile(
              icon: Iconsax.notification,
              title: 'Push Broadcast',
              subtitle: 'Send notifications to users',
              color: Colors.pink,
              onTap: () => context.push('/actions/broadcast'),
            ),
            _ActionTile(
              icon: Iconsax.award,
              title: 'Rexo Program Review',
              subtitle: 'Review program applications',
              color: Colors.amber,
              onTap: () => context.push('/actions/rexo-program'),
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
