import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

/// Provider for conversations list (unique sender/receiver pairs with latest message)
final conversationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // Fetch all messages where user is sender or receiver
  final sentMessages = await SupabaseService.client
      .from('messages')
      .select('*, receiver:users!receiver_id(id, name, avatar_url)')
      .eq('sender_id', user.id)
      .order('created_at', ascending: false)
      .limit(200);

  final receivedMessages = await SupabaseService.client
      .from('messages')
      .select('*, sender:users!sender_id(id, name, avatar_url)')
      .eq('receiver_id', user.id)
      .order('created_at', ascending: false)
      .limit(200);

  // Build conversations map: other_user_id -> latest message info
  final Map<String, Map<String, dynamic>> conversationsMap = {};

  for (final msg in List<Map<String, dynamic>>.from(sentMessages)) {
    final otherUser = msg['receiver'] as Map<String, dynamic>?;
    if (otherUser == null) continue;
    final otherUserId = otherUser['id'] as String?;
    if (otherUserId == null) continue;

    if (!conversationsMap.containsKey(otherUserId)) {
      conversationsMap[otherUserId] = {
        'other_user_id': otherUserId,
        'other_user_name': otherUser['name'] ?? 'User',
        'other_user_avatar': otherUser['avatar_url'],
        'last_message': msg['content'],
        'last_message_at': msg['created_at'],
        'is_read': true, // Sent messages are always "read" from our perspective
      };
    }
  }

  for (final msg in List<Map<String, dynamic>>.from(receivedMessages)) {
    final otherUser = msg['sender'] as Map<String, dynamic>?;
    if (otherUser == null) continue;
    final otherUserId = otherUser['id'] as String?;
    if (otherUserId == null) continue;

    if (!conversationsMap.containsKey(otherUserId)) {
      conversationsMap[otherUserId] = {
        'other_user_id': otherUserId,
        'other_user_name': otherUser['name'] ?? 'User',
        'other_user_avatar': otherUser['avatar_url'],
        'last_message': msg['content'],
        'last_message_at': msg['created_at'],
        'is_read': msg['is_read'] ?? false,
      };
    } else {
      // Check if this message is more recent
      final existing = conversationsMap[otherUserId]!;
      final existingDate =
          DateTime.tryParse((existing['last_message_at'] ?? '').toString()) ??
              DateTime(1970);
      final msgDate =
          DateTime.tryParse((msg['created_at'] ?? '').toString()) ??
              DateTime(1970);
      if (msgDate.isAfter(existingDate)) {
        conversationsMap[otherUserId] = {
          'other_user_id': otherUserId,
          'other_user_name': otherUser['name'] ?? 'User',
          'other_user_avatar': otherUser['avatar_url'],
          'last_message': msg['content'],
          'last_message_at': msg['created_at'],
          'is_read': msg['is_read'] ?? false,
        };
      } else if (!existing['is_read'] && !(msg['is_read'] ?? false)) {
        // Keep unread status
        existing['is_read'] = false;
      }
    }
  }

  // Convert to list and sort by last_message_at desc
  final conversations = conversationsMap.values.toList();
  conversations.sort((a, b) {
    final aDate =
        DateTime.tryParse((a['last_message_at'] ?? '').toString()) ??
            DateTime(1970);
    final bDate =
        DateTime.tryParse((b['last_message_at'] ?? '').toString()) ??
            DateTime(1970);
    return bDate.compareTo(aDate);
  });

  return conversations;
});

/// Search public users by handle or name to start a new chat (WhatsApp-style).
///
/// Excludes the current user and returns up to 20 matches. An empty/whitespace
/// query returns an empty list so the UI can show a hint instead of everyone.
final userSearchProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return [];

  final currentUser = SupabaseService.currentUser;

  var request = SupabaseService.client
      .from('users')
      .select('id, name, handle, avatar_url, is_verified')
      .or('handle.ilike.%$q%,name.ilike.%$q%');

  if (currentUser != null) {
    request = request.neq('id', currentUser.id);
  }

  final response = await request.limit(20);
  return List<Map<String, dynamic>>.from(response);
});

/// Provider for chat messages between current user and another user
final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // Fetch the most recent 100 messages sent by current user to other user
  final sent = await SupabaseService.client
      .from('messages')
      .select()
      .eq('sender_id', user.id)
      .eq('receiver_id', otherUserId)
      .order('created_at', ascending: false)
      .limit(100);

  // Fetch the most recent 100 messages received from other user
  final received = await SupabaseService.client
      .from('messages')
      .select()
      .eq('sender_id', otherUserId)
      .eq('receiver_id', user.id)
      .order('created_at', ascending: false)
      .limit(100);

  // Combine and sort by created_at ascending
  final List<Map<String, dynamic>> allMessages = [
    ...List<Map<String, dynamic>>.from(sent),
    ...List<Map<String, dynamic>>.from(received),
  ];

  allMessages.sort((a, b) {
    final aDate =
        DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(1970);
    final bDate =
        DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(1970);
    return aDate.compareTo(bDate);
  });

  // Mark received messages as read
  await SupabaseService.client
      .from('messages')
      .update({'is_read': true})
      .eq('sender_id', otherUserId)
      .eq('receiver_id', user.id)
      .eq('is_read', false);

  return allMessages;
});

/// Realtime stream provider for chat messages.
/// Subscribes to the messages table via Supabase Realtime for live updates.
/// This enables real-time message delivery without polling.
final chatMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) {
  final user = SupabaseService.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  final controller = StreamController<List<Map<String, dynamic>>>();

  // Initial fetch of messages
  Future<void> fetchMessages() async {
    try {
      final sent = await SupabaseService.client
          .from('messages')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', otherUserId)
          .order('created_at', ascending: false)
          .limit(100);

      final received = await SupabaseService.client
          .from('messages')
          .select()
          .eq('sender_id', otherUserId)
          .eq('receiver_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> allMessages = [
        ...List<Map<String, dynamic>>.from(sent),
        ...List<Map<String, dynamic>>.from(received),
      ];

      allMessages.sort((a, b) {
        final aDate = DateTime.tryParse((a['created_at'] ?? '').toString()) ??
            DateTime(1970);
        final bDate = DateTime.tryParse((b['created_at'] ?? '').toString()) ??
            DateTime(1970);
        return aDate.compareTo(bDate);
      });

      if (!controller.isClosed) {
        controller.add(allMessages);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Fetch initial messages
  fetchMessages();

  // Subscribe to realtime changes on the messages table, filtered to messages
  // relevant to this conversation (where the current user is the receiver).
  // This prevents unnecessary refetches on messages between other users.
  final channel = SupabaseService.client
      .channel('messages_${user.id}_$otherUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: user.id,
        ),
        callback: (payload) {
          // When a new message is received by this user, refetch conversation
          fetchMessages();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'sender_id',
          value: user.id,
        ),
        callback: (payload) {
          // When this user sends a message (from another device), refetch
          fetchMessages();
        },
      )
      .subscribe();

  // Cleanup on dispose
  ref.onDispose(() {
    controller.close();
    SupabaseService.client.removeChannel(channel);
  });

  return controller.stream;
});

/// Message actions notifier
class MessageActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MessageActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Send a message to another user
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      await SupabaseService.client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Refresh messages for this conversation
      ref.invalidate(chatMessagesProvider(receiverId));
      ref.invalidate(conversationsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Edit a message previously sent by the current user.
  ///
  /// Updates the message [content] and sets `edited_at = now()`. Requires:
  /// - non-empty content after trimming,
  /// - the current user to be the sender (guarded client-side and enforced by
  ///   the RLS/trigger on the `messages` table),
  /// - the target message to not already be unsent (edit is disallowed once a
  ///   message is unsent).
  ///
  /// Returns `true` on success, `false` on any precondition violation or
  /// database/RLS failure (leaving the message unchanged in that case).
  ///
  /// See design "Key Functions > editMessage" (Requirements 4.2, 4.4, 4.5, 4.6).
  Future<bool> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      // Precondition: non-empty content after trimming.
      final trimmed = newContent.trim();
      if (trimmed.isEmpty) return false;

      // Fetch the target row to guard client-side and to know which
      // conversation to invalidate.
      final row = await SupabaseService.client
          .from('messages')
          .select('sender_id, receiver_id, is_unsent')
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return false;

      final senderId = (row['sender_id'] ?? '').toString();
      final receiverId = (row['receiver_id'] ?? '').toString();
      final isUnsent = row['is_unsent'] == true;

      // Precondition: only the sender may edit, and not once unsent.
      if (senderId != user.id) return false;
      if (isUnsent) return false;

      await SupabaseService.client
          .from('messages')
          .update({
            'content': trimmed,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      _invalidateConversation(user.id, senderId, receiverId);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unsend a message previously sent by the current user.
  ///
  /// Sets `is_unsent = true`, which is terminal: the displayed content becomes
  /// empty for both participants and the message can no longer be edited. Only
  /// the sender may unsend (guarded client-side and enforced by RLS/trigger).
  ///
  /// Returns `true` on success, `false` on any precondition violation or
  /// database/RLS failure (leaving the message unchanged in that case).
  ///
  /// See design "Key Functions > unsendMessage" (Requirements 5.1, 5.3, 5.5).
  Future<bool> unsendMessage(String messageId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      final row = await SupabaseService.client
          .from('messages')
          .select('sender_id, receiver_id')
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return false;

      final senderId = (row['sender_id'] ?? '').toString();
      final receiverId = (row['receiver_id'] ?? '').toString();

      // Precondition: only the sender may unsend.
      if (senderId != user.id) return false;

      await SupabaseService.client
          .from('messages')
          .update({'is_unsent': true}).eq('id', messageId);

      _invalidateConversation(user.id, senderId, receiverId);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a message for the current user only ("delete for me").
  ///
  /// Appends the current user's id to the message's `deleted_for` set using set
  /// semantics (the id appears at most once). Any participant (sender or
  /// receiver) may do this; the other participant is unaffected. If the id is
  /// already present the call is a no-op and returns `true` (idempotent).
  ///
  /// Returns `true` on success, `false` on any precondition violation or
  /// database/RLS failure.
  ///
  /// See design "Key Functions > deleteForMe" (Requirements 6.1, 6.2, 6.4).
  Future<bool> deleteForMe(String messageId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      final row = await SupabaseService.client
          .from('messages')
          .select('sender_id, receiver_id, deleted_for')
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return false;

      final senderId = (row['sender_id'] ?? '').toString();
      final receiverId = (row['receiver_id'] ?? '').toString();

      // Precondition: caller must be a participant.
      if (senderId != user.id && receiverId != user.id) return false;

      // Set semantics: read the current set, add our id only if absent.
      final current = (row['deleted_for'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          <String>[];

      if (!current.contains(user.id)) {
        current.add(user.id);
        await SupabaseService.client
            .from('messages')
            .update({'deleted_for': current}).eq('id', messageId);
      }

      _invalidateConversation(user.id, senderId, receiverId);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Invalidate the providers affected by a soft-state change on a message.
  ///
  /// The chat providers are keyed by the *other* participant's user id, so we
  /// derive it from the message's sender/receiver relative to [currentUserId].
  /// The conversations list is always refreshed since previews may change.
  void _invalidateConversation(
    String currentUserId,
    String senderId,
    String receiverId,
  ) {
    final otherUserId = senderId == currentUserId ? receiverId : senderId;
    if (otherUserId.isNotEmpty) {
      ref.invalidate(chatMessagesProvider(otherUserId));
      ref.invalidate(chatMessagesStreamProvider(otherUserId));
    }
    ref.invalidate(conversationsProvider);
  }
}

/// Message actions provider
final messageActionsProvider =
    StateNotifierProvider<MessageActionsNotifier, AsyncValue<void>>((ref) {
  return MessageActionsNotifier(ref);
});
