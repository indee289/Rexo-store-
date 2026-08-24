import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_icon_button.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../services/supabase_service.dart';
import '../models/message_view.dart';
import '../providers/messages_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final success =
        await ref.read(messageActionsProvider.notifier).sendMessage(
              receiverId: widget.otherUserId,
              content: content,
            );

    if (success) {
      _scrollToBottom();
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.otherUserId));
    final conversationsAsync = ref.watch(conversationsProvider);

    // Get other user's name from conversations
    String otherUserName = 'User';
    String? otherUserAvatar;
    conversationsAsync.whenData((conversations) {
      final conv = conversations.where(
        (c) => c['other_user_id'] == widget.otherUserId,
      );
      if (conv.isNotEmpty) {
        otherUserName = conv.first['other_user_name'] ?? 'User';
        otherUserAvatar = conv.first['other_user_avatar'];
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.sm,
        title: Row(
          children: [
            PremiumIconButton(
              icon: Iconsax.arrow_left,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: AppSpacing.xs),
            _HeaderAvatar(
              imageUrl: otherUserAvatar,
              name: otherUserName,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    otherUserName,
                    style: AppTextStyles.labelLarge
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // Parse rows into the typed view model and filter out any
                // messages the current user deleted for themselves (Req 6.5).
                final currentUserId = SupabaseService.currentUser?.id ?? '';
                final views = messages
                    .map((m) => MessageView.fromMap(m))
                    .toList(growable: false);
                final visible = visibleMessages(views, currentUserId);

                if (visible.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // Build the flattened list of date separators + grouped
                // bubbles (Req 13.4).
                final items = _buildChatItems(visible, currentUserId);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _DateSeparatorItem) {
                      return _DateSeparator(date: item.date);
                    }
                    final msgItem = item as _MessageItem;
                    // Expose the actions hook only for the current user's own,
                    // non-unsent messages (the sheet is wired in task 9.3).
                    final onLongPress =
                        (msgItem.isMine && !msgItem.message.isUnsent)
                            ? () => _onMessageLongPress(msgItem.message)
                            : null;
                    return ChatBubble(
                      message: msgItem.message,
                      isMine: msgItem.isMine,
                      showTail: msgItem.showTail,
                      onLongPress: onLongPress,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Failed to load messages',
                    style: AppTextStyles.bodyMedium),
              ),
            ),
          ),

          // Message input — rounded pill field + blue circular send button.
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.darkSurfaceAlt
                            : AppColors.surfaceAlt,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSending ? Iconsax.timer : Iconsax.send_1,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared "no messages" empty state.
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message_text,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No messages yet',
            style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Say hello!', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  /// Opens the long-press message actions sheet (Requirements 4.1, 5.2, 6.1).
  ///
  /// Presents a [showPremiumSheet] titled "Message" containing the Edit /
  /// Unsend / Delete-for-me / Copy actions. Authorization mirrors the design's
  /// `onMessageAction` dispatch: Edit/Unsend are only offered for the current
  /// user's own, non-unsent message; Copy and Delete-for-me are always
  /// available. The sheet closes itself on a successful action and surfaces a
  /// snackbar on failure.
  void _onMessageLongPress(MessageView message) {
    final currentUserId = SupabaseService.currentUser?.id ?? '';
    final isMine = message.senderId == currentUserId;
    showPremiumSheet<void>(
      context: context,
      title: 'Message',
      child: _MessageActionsSheet(
        message: message,
        isMine: isMine,
        otherUserId: widget.otherUserId,
      ),
    );
  }

  /// Flattens [visible] (ascending by createdAt) into a render list of date
  /// separators and message items.
  ///
  /// - A [_DateSeparatorItem] is inserted before the first message and whenever
  ///   the calendar day changes between consecutive messages (Req 13.4).
  /// - Each [_MessageItem] carries a `showTail` flag that is `true` only for the
  ///   last message in a run of consecutive same-sender messages within the
  ///   same day, so grouped bubbles render a single tail.
  List<_ChatItem> _buildChatItems(
    List<MessageView> visible,
    String currentUserId,
  ) {
    final items = <_ChatItem>[];
    for (var i = 0; i < visible.length; i++) {
      final message = visible[i];
      final prev = i > 0 ? visible[i - 1] : null;

      final isNewDay =
          prev == null || !_isSameDay(prev.createdAt, message.createdAt);
      if (isNewDay) {
        items.add(_DateSeparatorItem(message.createdAt));
      }

      final next = i < visible.length - 1 ? visible[i + 1] : null;
      // Tail on the last message of a same-sender, same-day group.
      final showTail = next == null ||
          next.senderId != message.senderId ||
          !_isSameDay(next.createdAt, message.createdAt);

      items.add(_MessageItem(
        message: message,
        isMine: message.senderId == currentUserId,
        showTail: showTail,
      ));
    }
    return items;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Base type for entries rendered in the chat list.
abstract class _ChatItem {
  const _ChatItem();
}

/// A day divider inserted between messages on different days.
class _DateSeparatorItem extends _ChatItem {
  final DateTime date;
  const _DateSeparatorItem(this.date);
}

/// A single message bubble entry with its computed grouping metadata.
class _MessageItem extends _ChatItem {
  final MessageView message;
  final bool isMine;
  final bool showTail;
  const _MessageItem({
    required this.message,
    required this.isMine,
    required this.showTail,
  });
}

/// Centered day label separating messages from different days.
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Text(
          _label(date),
          style: AppTextStyles.caption.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d, yyyy').format(date);
  }
}


/// Bottom-sheet body for the long-press message actions (task 9.3).
///
/// Presents the Edit / Unsend / Delete-for-me / Copy actions and, when Edit is
/// chosen, swaps to an inline editor (a prefilled [PremiumTextField] plus a
/// Save [PremiumButton]). Dispatch and authorization follow the design's
/// `onMessageAction` algorithm:
///
/// - **Copy**: copies [MessageView.content] to the clipboard, shows a snackbar,
///   and closes.
/// - **Delete for me**: appends the caller to the message's deleted-for set
///   (any participant) via [MessageActionsNotifier.deleteForMe].
/// - **Edit**: offered only when [isMine] and the message is not unsent; save
///   is rejected when the trimmed text is empty, otherwise calls
///   [MessageActionsNotifier.editMessage].
/// - **Unsend**: offered only when [isMine]; calls
///   [MessageActionsNotifier.unsendMessage].
///
/// On success the sheet closes and the conversation is refreshed (the notifier
/// already invalidates `chatMessagesProvider(otherUserId)`; we invalidate it
/// again defensively). On failure a snackbar is shown and the sheet stays open.
///
/// Requirements: 4.1, 5.2, 6.1.
class _MessageActionsSheet extends ConsumerStatefulWidget {
  final MessageView message;
  final bool isMine;
  final String otherUserId;

  const _MessageActionsSheet({
    required this.message,
    required this.isMine,
    required this.otherUserId,
  });

  @override
  ConsumerState<_MessageActionsSheet> createState() =>
      _MessageActionsSheetState();
}

class _MessageActionsSheetState extends ConsumerState<_MessageActionsSheet> {
  late final TextEditingController _editController;
  bool _editing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppTextStyles.bodyMedium)),
    );
  }

  /// Closes the sheet and defensively refreshes the conversation. The notifier
  /// already invalidates `chatMessagesProvider(otherUserId)` on success; this
  /// second invalidation is a lightweight safety net (Req 13.5).
  void _closeOnSuccess() {
    ref.invalidate(chatMessagesProvider(widget.otherUserId));
    Navigator.of(context).maybePop();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Message copied', style: AppTextStyles.bodyMedium),
      ),
    );
  }

  Future<void> _unsend() async {
    // Authorization: only the sender may unsend.
    if (!widget.isMine) {
      _showSnack('Only the sender can do that.');
      return;
    }
    setState(() => _busy = true);
    final ok = await ref
        .read(messageActionsProvider.notifier)
        .unsendMessage(widget.message.id);
    if (!mounted) return;
    if (ok) {
      _closeOnSuccess();
    } else {
      setState(() => _busy = false);
      _showSnack("Couldn't update message.");
    }
  }

  Future<void> _deleteForMe() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(messageActionsProvider.notifier)
        .deleteForMe(widget.message.id);
    if (!mounted) return;
    if (ok) {
      _closeOnSuccess();
    } else {
      setState(() => _busy = false);
      _showSnack("Couldn't update message.");
    }
  }

  Future<void> _saveEdit() async {
    // Authorization: edit only for own, non-unsent messages.
    if (!widget.isMine || widget.message.isUnsent) {
      _showSnack('Only the sender can do that.');
      return;
    }
    // Reject empty-trimmed input.
    final trimmed = _editController.text.trim();
    if (trimmed.isEmpty) {
      _showSnack("Message can't be empty.");
      return;
    }
    setState(() => _busy = true);
    final ok = await ref
        .read(messageActionsProvider.notifier)
        .editMessage(messageId: widget.message.id, newContent: trimmed);
    if (!mounted) return;
    if (ok) {
      _closeOnSuccess();
    } else {
      setState(() => _busy = false);
      _showSnack("Couldn't update message.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _buildEditor();
    }
    return _buildActions();
  }

  Widget _buildActions() {
    // Edit is offered only for the current user's own, non-unsent message;
    // Unsend only for own messages; Copy and Delete-for-me are always shown.
    final canEdit = widget.isMine && !widget.message.isUnsent;
    final canUnsend = widget.isMine;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit)
          _ActionRow(
            icon: Iconsax.edit_2,
            label: 'Edit',
            onTap: _busy ? null : () => setState(() => _editing = true),
          ),
        if (canUnsend)
          _ActionRow(
            icon: Iconsax.slash,
            label: 'Unsend',
            onTap: _busy ? null : _unsend,
          ),
        _ActionRow(
          icon: Iconsax.trash,
          label: 'Delete for me',
          destructive: true,
          onTap: _busy ? null : _deleteForMe,
        ),
        _ActionRow(
          icon: Iconsax.copy,
          label: 'Copy',
          onTap: _busy ? null : _copy,
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumTextField.multiline(
          controller: _editController,
          hint: 'Edit message',
          minLines: 1,
          maxLines: 5,
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumButton(
          label: 'Save',
          icon: Iconsax.tick_circle,
          loading: _busy,
          onPressed: _busy ? null : _saveEdit,
        ),
      ],
    );
  }
}

/// A single tappable row in the message actions sheet (icon + label).
///
/// Token-driven only: colors come from [AppColors]/the theme, spacing from
/// [AppSpacing], and the corner radius from [AppRadius]. A `null` [onTap]
/// renders a dimmed, non-interactive row.
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        destructive ? AppColors.error : theme.colorScheme.onSurface;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}


/// Small chat-header avatar with a subtle green presence dot in the
/// bottom-right corner, matching the reference's "online" affordance.
///
/// The dot is decorative (the app has no presence backend) and uses the
/// [AppColors.success] token with a surface-colored rim so it reads cleanly.
class _HeaderAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _HeaderAvatar({required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    const size = PremiumAvatar.sizeSm;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PremiumAvatar(imageUrl: imageUrl, name: name, size: size),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
