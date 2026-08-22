import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/admin_provider.dart';

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  String? _filterActionType;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return _buildAccessDenied();

    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Audit Logs',
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
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter, color: AppColors.textPrimary),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          final filtered = _filterActionType != null
              ? logs.where((l) => l['action_type'] == _filterActionType).toList()
              : logs;

          if (filtered.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final log = filtered[index];
              return _buildLogCard(log);
            },
          );
        },
        loading: () => const ShimmerLoading(height: 400),
        error: (error, _) => _buildError(),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final actionType = log['action_type'] ?? 'unknown';
    final targetType = log['target_type'] ?? '';
    final targetId = log['target_id'] ?? '';
    final reason = log['reason'] ?? '';
    final createdAt = log['created_at'] ?? '';
    final adminId = log['admin_id'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF795548).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Iconsax.document, color: Color(0xFF795548), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionType.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$targetType: ${targetId.length > 8 ? targetId.substring(0, 8) : targetId}...',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  createdAt.toString().length >= 10
                      ? createdAt.toString().substring(0, 10)
                      : '',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            if (reason.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reason,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Admin: ${adminId.length > 8 ? adminId.substring(0, 8) : adminId}...',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final actionTypes = [
      null,
      'update_user_status',
      'update_user_role',
      'update_campaign_status',
      'approve_submission',
      'reject_submission',
      'approve_deposit',
      'reject_deposit',
      'approve_withdrawal',
      'reject_withdrawal',
      'approve_kyc',
      'reject_kyc',
      'credit_wallet',
      'debit_wallet',
      'freeze_wallet',
      'unfreeze_wallet',
      'resolve_dispute',
      'update_platform_setting',
      'send_broadcast',
      'create_product',
      'update_product',
      'delete_product',
      'update_order_status',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filter by Action Type',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: actionTypes.length,
                itemBuilder: (ctx, index) {
                  final type = actionTypes[index];
                  final label = type?.replaceAll('_', ' ') ?? 'All';
                  return RadioListTile<String?>(
                    value: type,
                    groupValue: _filterActionType,
                    title: Text(
                      label,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filterActionType = value;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Audit Logs', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
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
            const Icon(Iconsax.lock, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('Access Denied', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.document, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            _filterActionType != null ? 'No logs for this filter' : 'No audit logs yet',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Failed to load audit logs', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          TextButton(
            onPressed: () => ref.invalidate(adminAuditLogsProvider),
            child: Text('Retry', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
