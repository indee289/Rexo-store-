import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/admin_provider.dart';
import 'create_campaign_screen.dart';

/// Admin campaign control — rebuilt layout.
///
/// Old layout: a `PremiumAppBar`, a `FloatingActionButton` for create, and
/// admin-local `PremiumCard`s whose footer crammed five `_ActionButton` tiles
/// (Edit / Pause / Resume / Complete / Cancel) into one row — each a 9pt label
/// under a 16px icon, well under a usable tap target — plus a sixth
/// unlabelled `IconButton` for delete tucked up in the title row.
///
/// New layout: the collapsing large title with create as a pinned pill (the
/// app uses no floating action buttons); each card keeps Edit as a direct
/// action and moves the four lifecycle transitions and delete into a "Change
/// status" sheet, where they are full-width rows with real labels and real tap
/// targets. The status badge becomes a `GlassChip.status`.
///
/// `adminCampaignsProvider`, `updateCampaignStatus`, `deleteCampaign`, the
/// exact status strings ('paused' / 'active' / 'completed' / 'cancelled'), the
/// `CreateCampaignScreen(existingCampaign:)` edit route and the invalidation
/// after editing are unchanged.
class CampaignControlScreen extends ConsumerStatefulWidget {
  const CampaignControlScreen({super.key});

  @override
  ConsumerState<CampaignControlScreen> createState() =>
      _CampaignControlScreenState();
}

class _CampaignControlScreenState extends ConsumerState<CampaignControlScreen> {
  void _navigateToCreateCampaign() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCampaignScreen(),
      ),
    );
  }

  Future<void> _editCampaign(Map<String, dynamic> campaign) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCampaignScreen(existingCampaign: campaign),
      ),
    );
    ref.invalidate(adminCampaignsProvider);
  }

  void _setStatus(Object? id, String status) {
    ref.read(adminActionsProvider.notifier).updateCampaignStatus(id, status);
  }

  /// The four lifecycle transitions plus delete, as a sheet of real rows.
  void _showStatusSheet(Map<String, dynamic> campaign) {
    final id = campaign['id'];
    final title = campaign['title']?.toString() ?? 'this campaign';

    showGlassSheet<void>(
      context: context,
      title: 'Change status',
      subtitle: title,
      child: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassGroup(
              children: [
                GlassRow(
                  icon: AppIcons.pause,
                  iconColor: AppColors.warning,
                  title: 'Pause',
                  subtitle: 'Stop accepting new applicants',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(id, 'paused');
                  },
                ),
                GlassRow(
                  icon: AppIcons.play,
                  iconColor: AppColors.success,
                  title: 'Resume',
                  subtitle: 'Make the campaign active again',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(id, 'active');
                  },
                ),
                GlassRow(
                  icon: AppIcons.tick_circle,
                  title: 'Complete',
                  subtitle: 'Mark the campaign as finished',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(id, 'completed');
                  },
                ),
                GlassRow(
                  icon: AppIcons.close_circle,
                  iconColor: AppColors.error,
                  title: 'Cancel',
                  subtitle: 'Call the campaign off',
                  showChevron: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _setStatus(id, 'cancelled');
                  },
                ),
              ],
            ),
            AppSpacing.gapLg,
            GlassButton.destructive(
              label: 'Delete campaign',
              icon: AppIcons.trash,
              onPressed: () {
                Navigator.pop(sheetContext);
                _confirmDeleteCampaign(id.toString(), title);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCampaign(String campaignId, String title) async {
    final confirmed = await showGlassConfirm(
      context: context,
      title: 'Delete campaign',
      message: 'Permanently delete "$title"? This cannot be undone.',
      icon: AppIcons.trash,
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed) return;

    final success =
        await ref.read(adminActionsProvider.notifier).deleteCampaign(campaignId);

    if (!mounted) return;

    if (success) {
      showGlassSnackBar(
        context,
        message: 'Campaign deleted',
        tone: GlassToastTone.success,
      );
    } else {
      final actionState = ref.read(adminActionsProvider);
      final errorMsg = actionState.hasError
          ? ErrorUtils.sanitize(actionState.error)
          : 'Failed to delete campaign. Please try again.';
      showGlassSnackBar(
        context,
        message: errorMsg,
        tone: GlassToastTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(adminCampaignsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(adminCampaignsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const GlassLargeTitleHeader(
                  title: 'Campaign control',
                  subtitle: 'Create, edit and change status',
                  showBack: true,
                ),
                campaigns.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: GlassEmptyState(
                          icon: AppIcons.briefcase,
                          title: 'No campaigns found',
                          message: 'Create one to get started.',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        130,
                      ),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => AppSpacing.gapMd,
                        itemBuilder: (context, index) {
                          final campaign = list[index];
                          return RepaintBoundary(
                            child: _CampaignCard(
                              campaign: campaign,
                              onEdit: () => _editCampaign(campaign),
                              onChangeStatus: () => _showStatusSheet(campaign),
                            ),
                          );
                        },
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
                      onRetry: () => ref.invalidate(adminCampaignsProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'New campaign',
              icon: AppIcons.add,
              size: GlassButtonSize.large,
              onPressed: _navigateToCreateCampaign,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onEdit;
  final VoidCallback onChangeStatus;

  const _CampaignCard({
    required this.campaign,
    required this.onEdit,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = (campaign['status'] ?? 'unknown').toString();
    final description = (campaign['description'] ?? '').toString();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (campaign['title'] ?? 'Untitled').toString(),
                  style: AppTextStyles.headline
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppSpacing.gapSm,
              GlassChip.status(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            AppSpacing.gapSm,
            Text(
              description,
              maxLines: 2,
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
                child: GlassButton.outline(
                  label: 'Edit',
                  icon: AppIcons.edit,
                  size: GlassButtonSize.small,
                  onPressed: onEdit,
                ),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: GlassButton.glass(
                  label: 'Change status',
                  icon: AppIcons.setting_2,
                  size: GlassButtonSize.small,
                  onPressed: onChangeStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  if (status.isEmpty) return status;
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.success;
    case 'paused':
      return AppColors.warning;
    case 'completed':
      return AppColors.primary;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.neutral;
  }
}
