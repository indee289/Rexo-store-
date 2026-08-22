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
      .order('created_at', ascending: false);

  final receivedMessages = await SupabaseService.client
      .from('messages')
      .select('*, sender:users!sender_id(id, name, avatar_url)')
      .eq('receiver_id', user.id)
      .order('created_at', ascending: false);

  // Build conversations map: other_user_id -> latest message info
  final Map<String, Map<String, dynamic>> conversationsMap = {};

  for (final msg in List<Map<String, dynamic>>.from(sentMessages)) {
    final otherUser = msg['receiver'] as Map<String, dynamic>?;
    if (otherUser == null) continue;
    final otherUserId = otherUser['id'] as String;

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
    final otherUserId = otherUser['id'] as String;

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
      final existingDate = DateTime.parse(existing['last_message_at'] as String);
      final msgDate = DateTime.parse(msg['created_at'] as String);
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
    final aDate = DateTime.parse(a['last_message_at'] as String);
    final bDate = DateTime.parse(b['last_message_at'] as String);
    return bDate.compareTo(aDate);
  });

  return conversations;
});

/// Provider for chat messages between current user and another user
final chatMessagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // Fetch messages sent by current user to other user
  final sent = await SupabaseService.client
      .from('messages')
      .select()
      .eq('sender_id', user.id)
      .eq('receiver_id', otherUserId)
      .order('created_at', ascending: true);

  // Fetch messages received from other user
  final received = await SupabaseService.client
      .from('messages')
      .select()
      .eq('sender_id', otherUserId)
      .eq('receiver_id', user.id)
      .order('created_at', ascending: true);

  // Combine and sort by created_at ascending
  final List<Map<String, dynamic>> allMessages = [
    ...List<Map<String, dynamic>>.from(sent),
    ...List<Map<String, dynamic>>.from(received),
  ];

  allMessages.sort((a, b) {
    final aDate = DateTime.parse(a['created_at'] as String);
    final bDate = DateTime.parse(b['created_at'] as String);
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
    StreamProvider.family<List<Map<String, dynamic>>, String>(
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
          .order('created_at', ascending: true);

      final received = await SupabaseService.client
          .from('messages')
          .select()
          .eq('sender_id', otherUserId)
          .eq('receiver_id', user.id)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> allMessages = [
        ...List<Map<String, dynamic>>.from(sent),
        ...List<Map<String, dynamic>>.from(received),
      ];

      allMessages.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] as String);
        final bDate = DateTime.parse(b['created_at'] as String);
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

  // Subscribe to realtime changes on the messages table
  final channel = SupabaseService.client
      .channel('messages_$otherUserId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          // When a new message is inserted, refetch all messages
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
}

/// Message actions provider
final messageActionsProvider =
    StateNotifierProvider<MessageActionsNotifier, AsyncValue<void>>((ref) {
  return MessageActionsNotifier(ref);
});
