import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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

    if (success) _scrollToBottom();
    if (mounted) setState(() => _isSending = false);
  }

  void _showComingSoon(String kind) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$kind calls coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.otherUserId));
    final conversationsAsync = ref.watch(conversationsProvider);

    // Resolve header name/avatar
    String otherUserName = '';
    String? otherUserAvatar;
    conversationsAsync.whenData((conversations) {
      final conv = conversations.where(
        (c) => c['other_user_id'] == widget.otherUserId,
      );
      if (conv.isNotEmpty) {
        otherUserName =
            (conv.first['other_user_name'] ?? '').toString();
        otherUserAvatar =
            conv.first['other_user_avatar'] as String?;
      }
    });

    if (otherUserName.isEmpty || otherUserName == 'User') {
      final peer =
          ref.watch(chatPeerProvider(widget.otherUserId)).asData?.value;
      if (peer != null) {
        final peerName = (peer['name'] ?? '').toString().trim();
        final peerHandle = (peer['handle'] ?? '').toString().trim();
        if (peerName.isNotEmpty) {
          otherUserName = peerName;
        } else if (peerHandle.isNotEmpty) {
          otherUserName = '@$peerHandle';
        }
        otherUserAvatar ??= peer['avatar_url'] as String?;
      }
    }

    final displayName =
        otherUserName.isEmpty ? 'User' : otherUserName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.chevron_left,
                  size: 28, color: AppColors.textPrimary),
            ),
            PremiumAvatar(
              imageUrl: otherUserAvatar,
              name: displayName,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'online',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PremiumIconButton(
            icon: Iconsax.call,
            tooltip: 'Voice call',
            onPressed: () => _showComingSoon('Voice'),
          ),
          PremiumIconButton(
            icon: Iconsax.video,
            tooltip: 'Video call',
            onPressed: () => _showComingSoon('Video'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();

                final currentUserId =
                    SupabaseService.currentUser?.id ?? '';
                final views = messages
                    .map((m) => MessageView.fromMap(m))
                    .toList(growable: false);
                final visible =
                    visibleMessages(views, currentUserId);

                if (visible.isEmpty) return _buildEmptyState();

                final items = _buildChatItems(visible, currentUserId);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md),
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
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
              error: (e, _) => const Center(
                child: Text('Failed to load messages',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
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
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadius.allMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                              fontSize: 14, color: AppColors.textHint),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSending ? Iconsax.timer : Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_text, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('No messages yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('Say hello!',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
        ],
      ),
    );
  }

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

  List<_ChatItem> _buildChatItems(
      List<MessageView> visible, String currentUserId) {
    final items = <_ChatItem>[];
    for (var i = 0; i < visible.length; i++) {
      final message = visible[i];
      final prev = i > 0 ? visible[i - 1] : null;

      final isNewDay = prev == null ||
          !_isSameDay(prev.createdAt, message.createdAt);
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.pillAll,
          ),
          child: Text(
            _label(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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

class _MessageActionsSheetState
    extends ConsumerState<_MessageActionsSheet> {
  late final TextEditingController _editController;
  bool _editing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _editController =
        TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _closeOnSuccess() {
    ref.invalidate(chatMessagesProvider(widget.otherUserId));
    Navigator.of(context).maybePop();
  }

  Future<void> _copy() async {
    await Clipboard.setData(
        ClipboardData(text: widget.message.content));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Message copied')),
    );
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
        .editMessage(
            messageId: widget.message.id, newContent: trimmed);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEdit)
          _ActionRow(
            icon: Iconsax.edit_2,
            label: 'Edit',
            onTap:
                _busy ? null : () => setState(() => _editing = true),
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
    final color = destructive ? AppColors.error : AppColors.textPrimary;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
