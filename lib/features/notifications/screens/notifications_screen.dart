import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/notifications_provider.dart';

/// Notifications — rebuilt layout.
///
/// Old layout: `PremiumAppBar` with a `TextButton` action over a `ListView`
/// where every row was a full-bleed `Container` with a bottom `BorderSide`, a
/// 3px left strip for unread, and hardcoded `TextStyle`s. The date headers were
/// bare uppercase `Text`.
///
/// New layout: collapsing large title with the unread count; each date becomes
/// a proper titled section, so TODAY / YESTERDAY / EARLIER are real groups
/// rather than labels floating above a continuous ruled list; and unread state
/// is shown by a brand-tinted row plus a dot instead of a left edge strip.
///
/// `notificationsProvider`, `notificationActionsProvider.markAllAsRead`, the
/// live column names and the date grouping are unchanged.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            GlassLargeTitleHeader(
              title: 'Notifications',
              showBack: true,
              subtitle: notificationsAsync.maybeWhen(
                data: (n) {
                  final unread = n.where((x) => x['read'] != true).length;
                  return unread == 0 ? null : '$unread unread';
                },
                orElse: () => null,
              ),
              actions: [
                GlassButton.ghost(
                  label: 'Mark all read',
                  size: GlassButtonSize.small,
                  onPressed: () => ref
                      .read(notificationActionsProvider.notifier)
                      .markAllAsRead(),
                ),
              ],
            ),
            notificationsAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: GlassEmptyState(
                      icon: AppIcons.notification,
                      title: 'No notifications',
                      message: "You're all caught up!",
                    ),
                  );
                }
                final grouped = _groupByDate(notifications);
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final group = grouped[index];
                      final items =
                          group['items'] as List<Map<String, dynamic>>;
                      return GlassSection(
                        title: group['label'] as String,
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          index == 0 ? AppSpacing.sm : 0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        children: [
                          for (final n in items)
                            _NotificationRow(notification: n),
                        ],
                      );
                    },
                    childCount: grouped.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: GlassLoader(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: GlassErrorState(
                  title: 'Failed to load notifications',
                  message: 'Please try again.',
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
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
        final date =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final Map<String, dynamic> notification;

  static IconData _iconForType(String type) {
    switch (type) {
      case 'campaign':
        return AppIcons.briefcase;
      case 'wallet':
        return AppIcons.wallet_1;
      case 'message':
        return AppIcons.message;
      case 'follow':
        return AppIcons.people;
      case 'alert':
        return AppIcons.warning_2;
      default:
        return AppIcons.notification;
    }
  }

  static Color _colorForType(String type) {
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
    final timeStr =
        createdAt != null ? DateFormat('hh:mm a').format(createdAt) : '';

    return GlassRow(
      icon: _iconForType(type),
      iconColor: _colorForType(type),
      title: title,
      subtitle: body.isEmpty ? null : body,
      showChevron: false,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timeStr.isNotEmpty)
            Text(
              timeStr,
              style: AppTextStyles.caption1
                  .copyWith(color: AppColors.textHint),
            ),
          if (!isRead) ...[
            const SizedBox(height: 5),
            // Unread dot, replacing the 3px left edge strip.
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
