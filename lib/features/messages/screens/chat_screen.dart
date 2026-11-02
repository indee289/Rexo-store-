import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_glass.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../core/widgets/premium_avatar.dart';
import '../../../core/widgets/user_actions_menu.dart';
import '../../../services/supabase_service.dart';
import '../models/message_view.dart';
import '../providers/messages_provider.dart';
import '../widgets/chat_bubble.dart';

/// Chat thread — rebuilt layout.
///
/// Old layout: a raw Material `AppBar` holding an `IconButton`, the avatar and
/// the name in a hand-built `Row`; a composer made of a decorated `Container`
/// wrapping a bare `TextField` and a `GestureDetector` circle; bare
/// `CircularProgressIndicator` / `Text` for the loading, empty and error
/// states; and a `showPremiumSheet` of hand-rolled `_ActionRow`s for the
/// long-press menu. The screen also carried its own dark-mode colour set.
///
/// New layout: a fixed [GlassAppBar] — this is the one screen type that should
/// *not* use the collapsing large title, because the peer's identity has to
/// stay on screen while the thread scrolls — with the peer shown as an avatar
/// and name in its title slot; a composer built from the shared text field and
/// a filled icon button; the shared glass empty / error / loading states; and
/// the long-press menu rebuilt as grouped rows in a glass sheet. The
/// dark-mode colours are gone — the app is light mode only.
///
/// `chatMessagesStreamProvider`, `conversationsProvider`, `hiddenChatsProvider`,
/// `chatPeerProvider`, `messageActionsProvider` (send / read / unsend / edit),
/// `MessageView.fromMap`, `visibleMessages`, `ChatBubble` and the date-grouping
/// logic are all unchanged.
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
  void initState() {
    super.initState();
    // Mark the conversation as read as soon as the chat screen opens.
    // Use addPostFrameCallback so ref is available after first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messageActionsProvider.notifier)
          .markConversationRead(widget.otherUserId);
    });
  }

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

    final success = await ref
        .read(messageActionsProvider.notifier)
        .sendMessage(receiverId: widget.otherUserId, content: content);

    if (success) {
      _scrollToBottom();
      // Also mark as read since we just sent — our own messages count as read.
      ref
          .read(messageActionsProvider.notifier)
          .markConversationRead(widget.otherUserId);
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesStreamProvider(widget.otherUserId));
    final conversationsAsync = ref.watch(conversationsProvider);
    final hiddenAt = ref.watch(hiddenChatsProvider)[widget.otherUserId];

    // Resolve header name/avatar
    String otherUserName = '';
    String? otherUserAvatar;
    conversationsAsync.whenData((conversations) {
      final conv = conversations.where(
        (c) => c['other_user_id'] == widget.otherUserId,
      );
      if (conv.isNotEmpty) {
        otherUserName = (conv.first['other_user_name'] ?? '').toString();
        otherUserAvatar = conv.first['other_user_avatar'] as String?;
      }
    });

    if (otherUserName.isEmpty || otherUserName == 'User') {
      final peer =
          ref.watch(chatPeerProvider(widget.otherUserId)).asData?.value;
      if (peer != null) {
        final peerName = (peer['name'] ?? '').toString().trim();
        final peerHandle =
            (peer['username'] ?? '').toString().trim(); // live: username
        if (peerName.isNotEmpty) {
          otherUserName = peerName;
        } else if (peerHandle.isNotEmpty) {
          otherUserName = '@$peerHandle';
        }
        otherUserAvatar ??=
            peer['profileImage'] as String?; // live: profileImage
      }
    }

    final displayName = otherUserName.isEmpty ? 'User' : otherUserName;

    return GlassScaffold(
      resizeToAvoidBottomInset: true,
      appBar: GlassAppBar(
        title: displayName,
        showBack: true,
        // The peer, not a page name, is the subject of this screen.
        titleWidget: Row(
          children: [
            PremiumAvatar(
              imageUrl: otherUserAvatar,
              name: displayName,
              size: 36,
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text(
                displayName,
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          UserActionsMenu(
            targetUserId: widget.otherUserId,
            targetLabel: displayName,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();

                final currentUserId = SupabaseService.currentUser?.id ?? '';
                final views = messages
                    .map((m) => MessageView.fromMap(m))
                    .toList(growable: false);
                final visible = visibleMessages(
                  views,
                  currentUserId,
                  hiddenBefore: hiddenAt,
                );

                if (visible.isEmpty) return _buildEmptyState();

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
                    final onLongPress =
                        (msgItem.isMine && !msgItem.message.isUnsent)
                            ? () => _onMessageLongPress(msgItem.message)
                            : null;
                    return RepaintBoundary(
                      child: ChatBubble(
                        message: msgItem.message,
                        isMine: msgItem.isMine,
                        showTail: msgItem.showTail,
                        onLongPress: onLongPress,
                      ),
                    );
                  },
                );
              },
              loading: () => const GlassLoader(),
              error: (e, _) => GlassErrorState(
                title: "Couldn't load this chat",
                message: 'Check your connection and try again.',
                onRetry: () => ref.invalidate(
                  chatMessagesStreamProvider(widget.otherUserId),
                ),
              ),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  /// The message composer: a recessed well plus a filled send disc.
  Widget _buildComposer() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppGlass.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: GlassTextField.multiline(
                  controller: _messageController,
                  hint: 'Message…',
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              AppSpacing.gapSm,
              GlassIconButton.filled(
                icon: _isSending ? AppIcons.timer : AppIcons.send_1,
                tooltip: 'Send',
                size: 46,
                iconSize: 20,
                onTap: _isSending ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const GlassEmptyState(
      icon: AppIcons.message_text,
      title: 'No messages yet',
      message: 'Say hello to start the conversation.',
    );
  }

  void _onMessageLongPress(MessageView message) {
    final currentUserId = SupabaseService.currentUser?.id ?? '';
    final isMine = message.senderId == currentUserId;
    showGlassSheet<void>(
      context: context,
      title: 'Message',
      child: _MessageActionsSheet(
        message: message,
        isMine: isMine,
        otherUserId: widget.otherUserId,
      ),
    );
  }

  List<_ChatItem> _buildChatItems(
      List<MessageView> visible, String currentUserId) {
    final items = <_ChatItem>[];
    for (var i = 0; i < visible.length; i++) {
      final message = visible[i];
      final prev = i > 0 ? visible[i - 1] : null;

      final isNewDay =
          prev == null || !_isSameDay(prev.createdAt, message.createdAt);
      if (isNewDay) items.add(_DateSeparatorItem(message.createdAt));

      final next = i < visible.length - 1 ? visible[i + 1] : null;
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

abstract class _ChatItem {
  const _ChatItem();
}

class _DateSeparatorItem extends _ChatItem {
  final DateTime date;
  const _DateSeparatorItem(this.date);
}

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

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: GlassChip(label: _label(date), dense: true),
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

/// Message long-press actions sheet.
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

  void _showSnack(String message, [GlassToastTone tone = GlassToastTone.error]) {
    showGlassSnackBar(context, message: message, tone: tone);
  }

  void _closeOnSuccess() {
    ref.invalidate(chatMessagesStreamProvider(widget.otherUserId));
    Navigator.of(context).maybePop();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    if (!mounted) return;
    // Raise the toast before popping: the messenger lives above the sheet
    // route, so the toast outlives it, but the lookup needs a live context.
    showGlassSnackBar(
      context,
      message: 'Message copied',
      tone: GlassToastTone.success,
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _unsend() async {
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

  Future<void> _saveEdit() async {
    if (!widget.isMine || widget.message.isUnsent) {
      _showSnack('Only the sender can do that.');
      return;
    }
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
    if (_editing) return _buildEditor();
    return _buildActions();
  }

  Widget _buildActions() {
    final canEdit = widget.isMine && !widget.message.isUnsent;
    final canUnsend = widget.isMine;

    return GlassGroup(
      children: [
        if (canEdit)
          GlassRow(
            icon: AppIcons.edit_2,
            title: 'Edit',
            showChevron: false,
            onTap: _busy ? null : () => setState(() => _editing = true),
          ),
        if (canUnsend)
          GlassRow(
            icon: AppIcons.slash,
            title: 'Unsend',
            destructive: true,
            showChevron: false,
            onTap: _busy ? null : _unsend,
          ),
        GlassRow(
          icon: AppIcons.copy,
          title: 'Copy',
          showChevron: false,
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
        GlassTextField.multiline(
          controller: _editController,
          label: 'Edit message',
          hint: 'Edit message',
          minLines: 1,
          maxLines: 5,
        ),
        AppSpacing.gapLg,
        GlassButton(
          label: 'Save',
          icon: AppIcons.tick_circle,
          loading: _busy,
          onPressed: _busy ? null : _saveEdit,
        ),
      ],
    );
  }
}
