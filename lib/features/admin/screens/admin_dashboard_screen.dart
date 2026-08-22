import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return _buildAccessDenied(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(ref),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Users',
              stats['total_users'].toString(),
              Iconsax.people,
              AppColors.primary,
            ),
            _buildStatCard(
              'Active Campaigns',
              stats['active_campaigns'].toString(),
              Iconsax.briefcase,
              AppColors.success,
            ),
            _buildStatCard(
              'Pending Deposits',
              stats['pending_deposits'].toString(),
              Iconsax.money_recive,
              AppColors.warning,
            ),
            _buildStatCard(
              'Pending Withdrawals',
              stats['pending_withdrawals'].toString(),
              Iconsax.money_send,
              AppColors.error,
            ),
            _buildStatCard(
              'Platform Revenue',
              '\u20B9${(stats['total_earnings'] as double).toStringAsFixed(0)}',
              Iconsax.chart_2,
              const Color(0xFF2196F3),
            ),
            _buildStatCard(
              'Pending KYC',
              stats['pending_kyc'].toString(),
              Iconsax.shield_tick,
              const Color(0xFF9C27B0),
            ),
          ],
        );
      },
      loading: () => const ShimmerLoading(height: 300),
      error: (error, _) => Center(
        child: Column(
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Failed to load stats',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(adminStatsProvider),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Users', Iconsax.people, '/admin/users', AppColors.primary),
      _QuickAction('Campaigns', Iconsax.briefcase, '/admin/campaigns', AppColors.success),
      _QuickAction('Submissions', Iconsax.document_text, '/admin/submissions', const Color(0xFF2196F3)),
      _QuickAction('Deposits', Iconsax.money_recive, '/admin/deposits', AppColors.warning),
      _QuickAction('Withdrawals', Iconsax.money_send, '/admin/withdrawals', AppColors.error),
      _QuickAction('Shop', Iconsax.shop, '/admin/shop', const Color(0xFF009688)),
      _QuickAction('Disputes', Iconsax.message_question, '/admin/disputes', const Color(0xFFFF9800)),
      _QuickAction('KYC', Iconsax.shield_tick, '/admin/kyc', const Color(0xFF9C27B0)),
      _QuickAction('Wallets', Iconsax.wallet_1, '/admin/wallets', const Color(0xFF3F51B5)),
      _QuickAction('Settings', Iconsax.setting_2, '/admin/settings', AppColors.textSecondary),
      _QuickAction('Audit Logs', Iconsax.document, '/admin/audit-logs', const Color(0xFF795548)),
      _QuickAction('Broadcast', Iconsax.notification, '/admin/broadcast', const Color(0xFFE91E63)),
      _QuickAction('Rexo Program', Iconsax.crown_1, '/admin/rexo-program', const Color(0xFFFF5722)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return PremiumCard(
          onTap: () => context.push(action.route),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.lock,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have admin privileges.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _QuickAction(this.title, this.icon, this.route, this.color);
}
