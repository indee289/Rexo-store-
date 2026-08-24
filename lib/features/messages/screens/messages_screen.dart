import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/messages_provider.dart';

/// Premium iOS-style messaging inbox (Screen Inventory #8).
///
/// Renders each conversation with a [PremiumAvatar], the counterpart name, a
/// message preview, a timestamp, and an unread indicator (Requirements 13.1,
/// 13.2). Tapping a row navigates to the Chat screen for that user
/// (Requirement 13.3). Loading uses shimmer skeletons that match the final row
/// layout; the empty state uses the shared [EmptyState] primitive.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Messages', style: AppTextStyles.h5),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
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
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyState(
              icon: Iconsax.message,
              title: 'No messages yet',
              subtitle: 'Start a conversation with brands or creators',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                indent: 84,
                endIndent: AppSpacing.lg,
                color: theme.dividerColor,
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(conversation: conversation)
                    .staggeredEntrance(index);
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: 8,
          itemBuilder: (_, __) => const ShimmerConversationRow(),
        ),
        error: (e, _) => EmptyState(
          icon: Iconsax.warning_2,
          title: 'Failed to load messages',
          subtitle: ErrorUtils.sanitize(e),
        ),
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

/// A single premium conversation row.
class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUserId = conversation['other_user_id'] as String;
    final name = conversation['other_user_name'] as String? ?? 'User';
    final avatarUrl = conversation['other_user_avatar'] as String?;
    final lastMessage = conversation['last_message'] as String? ?? '';
    final lastMessageAt =
        DateTime.tryParse(conversation['last_message_at'] ?? '');
    final isRead = conversation['is_read'] == true;
    final isUnread = !isRead;
    final timeStr = lastMessageAt != null ? _formatTime(lastMessageAt) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: PremiumAvatar(
        imageUrl: avatarUrl,
        name: name,
        size: 52,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeStr,
            style: AppTextStyles.caption.copyWith(
              color: isUnread
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                  color: isUnread
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
      onTap: () => context.push('/messages/$otherUserId'),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}

/// A premium "new chat" search sheet. Lets the user search public users by
/// handle or name and tap a result to open the existing Chat screen.
///
/// Rendered inside [showPremiumSheet], which supplies the grab handle, title
/// row (with a close button) and safe-area padding — so this widget only owns
/// the search field and the results list.
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
    final theme = Theme.of(context);
    final resultsAsync = ref.watch(userSearchProvider(_query));

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
                ? _hint(theme, 'Search for people to start a conversation')
                : resultsAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return _hint(theme, 'No users found');
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 72,
                          color: theme.dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          return _UserResultTile(user: users[index]);
                        },
                      );
                    },
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                    error: (e, _) => _hint(theme, ErrorUtils.sanitize(e)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hint(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserResultTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = user['id'] as String;
    final name = (user['name'] ?? 'User').toString();
    final handle = (user['handle'] ?? '').toString();
    final avatarUrl = user['avatar_url'] as String?;
    final isVerified = user['is_verified'] == true;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.xs),
      leading: PremiumAvatar(
        imageUrl: avatarUrl,
        name: name,
        size: 46,
        isVerified: isVerified,
      ),
      title: Text(
        name,
        style: AppTextStyles.labelLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: handle.isNotEmpty
          ? Text(
              '@$handle',
              style: AppTextStyles.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        context.push('/messages/$id');
      },
    );
  }
}
