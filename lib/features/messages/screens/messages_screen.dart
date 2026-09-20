import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/messages_provider.dart';

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
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Messages',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PremiumIconButton(
              icon: Iconsax.message_text,
              tooltip: 'New chat',
              background: true,
              tonal: true,
              onPressed: () => _openNewChatSearch(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: PremiumTextField.search(
              controller: _searchController,
              hint: 'Search',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // ── Conversation list ───────────────────────────────────────────
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const EmptyState(
                    icon: Iconsax.message,
                    title: 'No messages yet',
                    subtitle: 'Start a conversation',
                  );
                }

                final filtered = _filter(conversations);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Iconsax.search_normal,
                    title: 'No matches',
                    subtitle: 'Try a different name',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(conversationsProvider);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];
                      return _ConversationTile(conversation: conversation)
                          .staggeredEntrance(index);
                    },
                  ),
                );
              },
              loading: () => ListView.builder(
                itemCount: 8,
                itemBuilder: (_, __) => const ShimmerConversationRow(),
              ),
              error: (e, _) => EmptyState(
                icon: Iconsax.warning_2,
                title: 'Failed to load messages',
                subtitle: ErrorUtils.sanitize(e),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openNewChatSearch(BuildContext context) {
    showPremiumSheet<void>(
      context: context,
      title: 'New Chat',
      child: const _NewChatSheet(),
    );
  }
}

/// Single conversation row — Instagram-style.
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const _ConversationTile({required this.conversation});

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
    final timeStr =
        lastMessageAt != null ? _formatTime(lastMessageAt) : '';
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/messages/$otherUserId'),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).dividerColor, width: 1)),
          ),
          child: Row(
            children: [
              // Avatar
              PremiumAvatar(
                imageUrl: avatarUrl,
                name: name,
                size: 48,
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread
                                ? AppColors.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant,
                              fontWeight: isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          PremiumTextField.search(
            controller: _controller,
            hint: 'Search by name or @handle',
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Text(
                      'Search for people to start a conversation',
                      style: TextStyle(
                          fontSize: 14, color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : resultsAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text('No users found',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant)),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final userId =
                              user['user_id'] as String? ?? '';
                          final name = user['name'] as String? ?? 'User';
                          final handle =
                              user['handle'] as String? ?? '';
                          final avatarUrl =
                              user['avatar_url'] as String?;
                          return ListTile(
                            leading: PremiumAvatar(
                              imageUrl: avatarUrl,
                              name: name,
                              size: 44,
                            ),
                            title: Text(name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                            subtitle: handle.isNotEmpty
                                ? Text('@$handle',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant))
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/messages/$userId');
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        ErrorUtils.sanitize(e),
                        style: TextStyle(
                            color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
