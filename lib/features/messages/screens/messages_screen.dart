import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/admin_notify.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../admin/providers/is_admin_provider.dart';
import '../providers/messages_provider.dart';

/// Messages — rebuilt layout.
///
/// Old layout: a `PremiumAppBar` over a `Column` whose search field and
/// support shortcut scrolled away with the list, and a conversation list of
/// fixed 72px rows separated by full-bleed bottom borders. States came from
/// the old `EmptyState` / `ShimmerConversationRow` widgets, the delete
/// confirmation was an `AlertDialog`, and the new-chat sheet was a
/// `showPremiumSheet` full of `ListTile`s and `Divider`s.
///
/// New layout: a collapsing large title with the search field **pinned** into
/// the header, so it stays reachable however far the list is scrolled; the
/// support shortcut as a brand-tinted card; and conversations as discrete
/// spaced cards rather than bordered rows, which also makes swipe-to-delete
/// read correctly (a row sliding out of a shared pane does not). Every state
/// now comes from the shared glass set.
///
/// `visibleConversationsProvider`, `isAdminProvider`, `conversationsProvider`,
/// `hiddenChatsProvider.hide`, `messageActionsProvider.markConversationRead`,
/// `userSearchProvider`, `AdminNotify.supportAdminId` and the
/// `/messages/<id>` routes are all unchanged.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens a chat straight with the Campster admin (support).
  Future<void> _openSupportChat() async {
    final router = GoRouter.of(context);
    final adminId = await AdminNotify.supportAdminId();
    if (!mounted) return;
    if (adminId == null) {
      showGlassSnackBar(
        context,
        message: 'Support chat is unavailable right now.',
        tone: GlassToastTone.warning,
      );
      return;
    }
    router.push('/messages/$adminId');
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((c) => (c['other_user_name'] as String? ?? '')
            .toLowerCase()
            .contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(visibleConversationsProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return GlassScaffold(
      padBodyForAppBar: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(conversationsProvider);
        },
        child: CustomScrollView(
          slivers: [
            GlassLargeTitleHeader(
              title: 'Messages',
              actions: [
                GlassIconButton(
                  icon: AppIcons.edit_2,
                  tooltip: 'New chat',
                  size: 36,
                  iconSize: 19,
                  onTap: () => _openNewChatSearch(context),
                ),
              ],
              // Pinned so search survives scrolling the whole inbox.
              bottom: GlassHeaderSearch(
                child: GlassTextField.search(
                  controller: _searchController,
                  hint: 'Search',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              bottomHeight: GlassHeaderSearch.height,
            ),

            // Support shortcut — hidden for admins, who are the other end.
            if (!isAdmin)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: GlassCard.brand(
                    onTap: _openSupportChat,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const GlassIconBubble(
                          icon: AppIcons.message_text,
                          color: AppColors.primary,
                        ),
                        AppSpacing.gapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Campster Support',
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Need help? Chat directly with the admin',
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,
                        const Icon(
                          AppIcons.arrow_right_3,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            ...conversationsAsync.when(
              data: _conversationSlivers,
              loading: () => const [
                SliverFillRemaining(child: GlassListSkeleton(itemCount: 8)),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassErrorState(
                    title: "Couldn't load your messages",
                    message: ErrorUtils.sanitize(e),
                    onRetry: () => ref.invalidate(conversationsProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The data branch, as slivers so the list shares the header's scroll view.
  List<Widget> _conversationSlivers(
    List<Map<String, dynamic>> conversations,
  ) {
    if (conversations.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: GlassEmptyState(
            icon: AppIcons.message,
            title: 'No messages yet',
            message: "Start a conversation and it'll show up here.",
          ),
        ),
      ];
    }

    final filtered = _filter(conversations);
    if (filtered.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: GlassEmptyState(
            icon: AppIcons.search_normal,
            title: 'No matches',
            message: 'Try a different name.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        sliver: SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => AppSpacing.gapSm,
          itemBuilder: (context, index) {
            final conversation = filtered[index];
            final peerId = conversation['other_user_id'] as String;
            return RepaintBoundary(
              child: Dismissible(
                key: ValueKey('conv_$peerId'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) => _deleteConversation(conversation),
                background: const _DeleteBackground(),
                child: _ConversationTile(
                  conversation: conversation,
                  onLongPress: () async {
                    if (await _confirmDelete(context)) {
                      _deleteConversation(conversation);
                    }
                  },
                ),
              ).staggeredEntrance(index),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Text(
            'Swipe left or long-press a chat to delete it',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption1.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
      ),
    ];
  }

  Future<bool> _confirmDelete(BuildContext context) {
    return showGlassConfirm(
      context: context,
      title: 'Delete chat?',
      message: 'This removes the chat from your inbox only. '
          'The other person will still have it.',
      icon: AppIcons.trash,
      confirmLabel: 'Delete',
      destructive: true,
    );
  }

  void _deleteConversation(Map<String, dynamic> conversation) {
    final peerId = conversation['other_user_id'] as String;
    final marker =
        DateTime.tryParse((conversation['last_message_at'] ?? '').toString()) ??
            DateTime.now();
    ref.read(hiddenChatsProvider.notifier).hide(peerId, marker);
    ref.read(messageActionsProvider.notifier).markConversationRead(peerId);
    if (mounted) {
      showGlassSnackBar(context, message: 'Chat deleted');
    }
  }

  void _openNewChatSearch(BuildContext context) {
    showGlassSheet<void>(
      context: context,
      title: 'New chat',
      subtitle: 'Search for someone to message',
      child: const _NewChatSheet(),
    );
  }
}

/// Swipe-to-delete backdrop, shaped like the card it sits behind.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.allLg,
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: AppSpacing.xl),
          child: Icon(AppIcons.trash, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Single conversation card.
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback? onLongPress;
  const _ConversationTile({required this.conversation, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final otherUserId = conversation['other_user_id'] as String;
    final name = conversation['other_user_name'] as String? ?? 'User';
    final avatarUrl = conversation['other_user_avatar'] as String?;
    final lastMessage = conversation['last_message'] as String? ?? '';
    final lastMessageAt =
        DateTime.tryParse(conversation['last_message_at'] ?? '');
    final isRead = conversation['is_read'] == true;
    final isUnread = !isRead;
    final timeStr = lastMessageAt != null ? _formatTime(lastMessageAt) : '';

    return GlassCard(
      onTap: () => context.push('/messages/$otherUserId'),
      onLongPress: onLongPress,
      // An unread thread gets the brand rim, so the inbox is scannable
      // without relying on weight alone.
      rim: isUnread ? AppColors.primaryRim : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          PremiumAvatar(imageUrl: avatarUrl, name: name, size: 48),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  lastMessage,
                  style: AppTextStyles.footnote.copyWith(
                    color: isUnread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: AppTextStyles.caption1.copyWith(
                  color: isUnread ? AppColors.primary : AppColors.textHint,
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              // Reserve the dot's space either way so the time never shifts.
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isUnread ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dateTime);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dateTime);
    return DateFormat('dd/MM').format(dateTime);
  }
}

/// New chat search sheet.
class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet();

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchProvider(_query));

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          GlassTextField.search(
            controller: _controller,
            hint: 'Search by name or @handle',
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: _query.trim().isEmpty
                ? const GlassEmptyState(
                    icon: AppIcons.search_normal,
                    title: 'Find someone',
                    message: 'Search for people to start a conversation.',
                    compact: true,
                  )
                : resultsAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const GlassEmptyState(
                          icon: AppIcons.user,
                          title: 'No users found',
                          message: 'Try a different name or handle.',
                          compact: true,
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => AppSpacing.gapSm,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userId =
                              user['uid'] as String? ?? ''; // live: uid
                          final name = user['name'] as String? ?? 'User';
                          final username = user['username'] as String? ??
                              ''; // live: username
                          final avatarUrl = user['profileImage']
                              as String?; // live: profileImage
                          return RepaintBoundary(
                            child: GlassListCard(
                              leading: PremiumAvatar(
                                imageUrl: avatarUrl,
                                name: name,
                                size: 44,
                              ),
                              title: name,
                              subtitle:
                                  username.isNotEmpty ? '@$username' : null,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/messages/$userId');
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const GlassLoader(),
                    error: (e, _) => GlassErrorState(
                      message: ErrorUtils.sanitize(e),
                      compact: true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
