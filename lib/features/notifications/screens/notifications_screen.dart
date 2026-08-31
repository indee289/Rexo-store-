import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: PremiumAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationActionsProvider.notifier).markAllAsRead();
            },
            child: Text(
              'Mark All Read',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // Group by date
          final grouped = _groupByDate(notifications);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                final items =
                    group['items'] as List<Map<String, dynamic>>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        group['label'] as String,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (var i = 0; i < items.length; i++)
                      _NotificationTile(notification: items[i])
                          .staggeredEntrance(i),
                  ],
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerCard(height: 80),
          ),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load notifications',
              style: AppTextStyles.bodyMedium),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Iconsax.notification,
      title: 'No notifications yet',
      subtitle: 'We will notify you when something happens',
    );
  }

  List<Map<String, dynamic>> _groupByDate(
      List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final List<Map<String, dynamic>> todayItems = [];
    final List<Map<String, dynamic>> yesterdayItems = [];
    final List<Map<String, dynamic>> earlierItems = [];

    for (final n in notifications) {
      final createdAt = DateTime.tryParse(n['created_at'] ?? '');
      if (createdAt == null) {
        earlierItems.add(n);
        continue;
      }
      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
      if (date == today) {
        todayItems.add(n);
      } else if (date == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    final groups = <Map<String, dynamic>>[];
    if (todayItems.isNotEmpty) {
      groups.add({'label': 'Today', 'items': todayItems});
    }
    if (yesterdayItems.isNotEmpty) {
      groups.add({'label': 'Yesterday', 'items': yesterdayItems});
    }
    if (earlierItems.isNotEmpty) {
      groups.add({'label': 'Earlier', 'items': earlierItems});
    }

    return groups;
  }
}

class _NotificationTile extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRead = notification['is_read'] == true;
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? 'general';
    final id = notification['id'] as String;
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '');
    final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl - 4),
        color: AppColors.error.withOpacity(0.1),
        child: const Icon(Iconsax.trash, color: AppColors.error),
      ),
      onDismissed: (_) {
        ref.read(notificationActionsProvider.notifier).deleteNotification(id);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            ref.read(notificationActionsProvider.notifier).markAsRead(id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppRadius.allMd,
            border: Border(
              left: BorderSide(
                color: isRead ? Colors.transparent : AppColors.primary,
                width: isRead ? 0 : 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.1),
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight:
                            isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(timeAgo, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'campaign':
        return Iconsax.volume_high;
      case 'payment':
        return Iconsax.wallet;
      case 'order':
        return Iconsax.shopping_bag;
      case 'message':
        return Iconsax.message;
      case 'application':
        return Iconsax.document;
      default:
        return Iconsax.notification;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'campaign':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'order':
        return AppColors.roleBrand;
      case 'message':
        return AppColors.roleAdmin;
      case 'application':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dateTime);
  }
}
