import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(notificationActionsProvider.notifier)
                  .markAllAsRead();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Iconsax.notification,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            );
          }

          final grouped = _groupByDate(notifications);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                final items =
                    group['items'] as List<Map<String, dynamic>>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 8),
                      child: Text(
                        group['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    for (var i = 0; i < items.length; i++)
                      _NotificationTile(
                              notification: items[i])
                          .staggeredEntrance(i),
                  ],
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 8,
          itemBuilder: (_, __) => const ShimmerLoading(height: 72),
        ),
        error: (e, _) => const EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load notifications',
          subtitle: 'Please try again.',
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(
      List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final notification in notifications) {
      // Live column is "createdAt" (camelCase)
      final createdAt =
          DateTime.tryParse(notification['createdAt']?.toString() ?? '');
      String label;
      if (createdAt != null) {
        final date = DateTime(
            createdAt.year, createdAt.month, createdAt.day);
        if (date == today) {
          label = 'TODAY';
        } else if (date == yesterday) {
          label = 'YESTERDAY';
        } else {
          label = 'EARLIER';
        }
      } else {
        label = 'EARLIER';
      }
      groups.putIfAbsent(label, () => []).add(notification);
    }

    const order = ['TODAY', 'YESTERDAY', 'EARLIER'];
    return order
        .where((key) => groups.containsKey(key))
        .map((key) => {'label': key, 'items': groups[key]!})
        .toList();
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? '';
    // Live column is 'message' (not 'body')
    final body = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'general';
    // Live column is 'read' (not 'is_read')
    final isRead = notification['read'] == true;
    // Live column is 'createdAt' (not 'created_at')
    final createdAt =
        DateTime.tryParse(notification['createdAt']?.toString() ?? '');
    final timeStr = createdAt != null
        ? DateFormat('hh:mm a').format(createdAt)
        : '';

    final iconData = _iconForType(type);
    final iconColor = _colorForType(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurfaceVariant;
    final textHint =
        isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Container(
      decoration: BoxDecoration(
        color: isRead
            ? Colors.transparent
            : AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left teal strip for unread
          Container(
            width: 3,
            height: 72,
            color: isRead ? Colors.transparent : AppColors.primary,
          ),
          const SizedBox(width: 12),
          // Icon in colored circle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(iconData, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Time
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 12, 0),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                color: textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'campaign':
        return Iconsax.briefcase;
      case 'wallet':
        return Iconsax.wallet_1;
      case 'message':
        return Iconsax.message;
      case 'follow':
        return Iconsax.people;
      case 'alert':
        return Iconsax.warning_2;
      default:
        return Iconsax.notification;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'campaign':
        return AppColors.primary;
      case 'wallet':
        return AppColors.success;
      case 'message':
        return AppColors.accentPurple;
      case 'follow':
        return AppColors.accentPink;
      case 'alert':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
