import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/admin_notify.dart';
import '../../../services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blocks/providers/block_provider.dart';

/// Messaging providers backed by the live `chat_rooms` + `chat_messages`
/// tables.
///
/// Live schema (camelCase):
///   chat_rooms(id text PK, type, participants jsonb [user-id strings],
///              lastMessage, lastMessageSenderId, lastMessageAt, lastUpdate,
///              unreadCount jsonb, ...)
///   chat_messages(id uuid, chatRoomId text FK, senderId text, text, type,
///                 imageUrl, status, timestamp timestamptz, readBy jsonb,
///                 isEdited bool, updatedAt, reactions jsonb)
///
/// Room membership is the current user's id string being present in the
/// `participants` jsonb array. That id equals `SupabaseService.currentUser.id`
/// (which is the same value stored in `users.uid`), so peer lookups query the
/// `users` table by `uid`.

/// Deterministic direct-chat room id for a pair of user ids.
///
/// Direct (1:1) rooms are keyed by the sorted pair of participant ids so both
/// sides resolve to the same room regardless of who opens the chat first.
String _directRoomId(String a, String b) {
  final pair = [a, b]..sort();
  return 'dm_${pair[0]}_${pair[1]}';
}

/// Provider for the conversations list shown on the Messages screen.
///
/// Returns one entry per chat room the current user participates in, newest
/// activity first. Each entry uses the keys the UI already expects:
/// `other_user_id`, `other_user_name`, `other_user_avatar`, `last_message`,
/// `last_message_at`, `is_read`.
///
/// Implemented as a StreamProvider so the inbox updates in real-time when
/// chat_rooms rows change (new messages, room creation, etc.).
final conversationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = SupabaseService.currentUser;
  if (user == null) return Stream.value([]);

  final controller = StreamController<List<Map<String, dynamic>>>();
  RealtimeChannel? channel;
  Timer? refetchDebounce;

  // The Realtime channel is not row-filtered (jsonb "participants" cannot be
  // used in a realtime filter), so ANY room change would trigger a full
  // refetch. Coalesce bursts into a single refetch.
  void scheduleRefetch(Future<void> Function() run) {
    refetchDebounce?.cancel();
    refetchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!controller.isClosed) run();
    });
  }

  Future<void> fetchConversations() async {
    try {
      final rooms = await SupabaseService.client
          .from('chat_rooms')
          .select()
          .filter('participants', 'cs', '["${user.id}"]')
          .order('lastMessageAt', ascending: false)
          .limit(200);

      final roomRows = List<Map<String, dynamic>>.from(rooms);

      final blockedIds = await fetchBlockRelationIds();

      final peerIds = <String>{};
      for (final room in roomRows) {
        final peerId = _otherParticipant(room, user.id);
        if (peerId != null && !blockedIds.contains(peerId))
          peerIds.add(peerId);
      }

      final peersById = <String, Map<String, dynamic>>{};
      if (peerIds.isNotEmpty) {
        final peers = await SupabaseService.client
            .from('users')
            .select('uid, name, username, profileImage')
            .inFilter('uid', peerIds.toList());
        for (final p in List<Map<String, dynamic>>.from(peers)) {
          final id = (p['uid'] ?? '').toString();
          if (id.isNotEmpty) peersById[id] = p;
        }
      }

      final conversations = <Map<String, dynamic>>[];
      for (final room in roomRows) {
        final peerId = _otherParticipant(room, user.id);
        if (peerId == null || blockedIds.contains(peerId)) continue;
        final peer = peersById[peerId];
        conversations.add({
          'other_user_id': peerId,
          'other_user_name':
              (peer?['name'] ?? peer?['username'] ?? 'User').toString(),
          'other_user_avatar': peer?['profileImage'] as String?,
          'last_message': (room['lastMessage'] ?? '').toString(),
          'last_message_at':
              (room['lastMessageAt'] ?? room['lastUpdate'] ?? '').toString(),
          'is_read': _unreadFor(room, user.id) == 0,
        });
      }

      conversations.sort((a, b) {
        final aDate =
            DateTime.tryParse((a['last_message_at'] ?? '').toString()) ??
                DateTime(1970);
        final bDate =
            DateTime.tryParse((b['last_message_at'] ?? '').toString()) ??
                DateTime(1970);
        return bDate.compareTo(aDate);
      });

      if (!controller.isClosed) controller.add(conversations);

      channel ??= SupabaseService.client
          .channel('chat_rooms_${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_rooms',
            callback: (_) => scheduleRefetch(fetchConversations),
          )
          .subscribe();
    } catch (_) {
      if (!controller.isClosed) controller.add([]);
    }
  }

  fetchConversations();

  ref.onDispose(() {
    refetchDebounce?.cancel();
    controller.close();
    if (channel != null) {
      SupabaseService.client.removeChannel(channel!);
    }
  });

  return controller.stream;
});

/// Returns the id of the participant that is not [selfId], or `null` when the
/// room has no distinct other participant.
String? _otherParticipant(Map<String, dynamic> room, String selfId) {
  final participants = (room['participants'] as List?)
          ?.where((e) => e != null)
          .map((e) => e.toString())
          .toList() ??
      const <String>[];
  for (final p in participants) {
    if (p != selfId) return p;
  }
  return null;
}

/// Reads the current user's unread count from the room's `unreadCount` jsonb
/// map, defaulting to 0 when absent or malformed.
int _unreadFor(Map<String, dynamic> room, String selfId) {
  final unread = room['unreadCount'];
  if (unread is Map) {
    final value = unread[selfId];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// Search public users by username or name to start a new chat (WhatsApp-style).
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
      .select('uid, name, username, profileImage, isVerified') // live columns
      .or('username.ilike.%$q%,name.ilike.%$q%');

  if (currentUser != null) {
    request = request.neq('uid', currentUser.id);
  }

  final response = await request.limit(20);
  final results = List<Map<String, dynamic>>.from(response);

  // Exclude users in a block relationship (either direction).
  final blockedIds = await fetchBlockRelationIds();
  if (blockedIds.isEmpty) return results;
  return results
      .where((u) => !blockedIds.contains((u['uid'] ?? '').toString()))
      .toList();
});

/// Fetches the public profile row for a chat peer by user id.
///
/// Used by the Chat screen to resolve the header name/avatar when the
/// conversation is brand-new (no messages yet). Returns the peer's public
/// columns (`uid, name, username, profileImage, isVerified`) or `null` when no
/// matching row exists.
final chatPeerProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, userId) async {
  if (userId.isEmpty) return null;

  final row = await SupabaseService.client
      .from('users')
      .select('uid, name, username, profileImage, isVerified') // live columns
      .eq('uid', userId)
      .maybeSingle();

  return row;
});

/// Resolves the chat room id shared by the current user and [otherUserId], if
/// one already exists. Returns `null` when the two have never chatted.
Future<String?> _findRoomId(String selfId, String otherUserId) async {
  try {
    final rooms = await SupabaseService.client
        .from('chat_rooms')
        .select('id, participants')
        .filter('participants', 'cs', '["$selfId"]')
        .limit(200);

    for (final room in List<Map<String, dynamic>>.from(rooms)) {
      final participants = (room['participants'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      if (participants.contains(otherUserId)) {
        return (room['id'] ?? '').toString();
      }
    }
  } catch (_) {
    // Query failed — return null (no room found)
  }
  return null;
}

/// Provider for the chat messages between the current user and [otherUserId].
///
/// Resolves the shared room, then loads its `chat_messages` ordered oldest
/// first. Returns an empty list when no room exists yet (a brand-new chat).
final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) async {
  try {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    final roomId = await _findRoomId(user.id, otherUserId);
    if (roomId == null) return [];

    final messages = await SupabaseService.client
        .from('chat_messages')
        .select()
        .eq('chatRoomId', roomId)
        .order('timestamp', ascending: true)
        .limit(200);

    return List<Map<String, dynamic>>.from(messages);
  } catch (_) {
    return [];
  }
});

/// Realtime stream provider for chat messages with [otherUserId].
///
/// Does an initial load, then subscribes to inserts/updates on `chat_messages`
/// (schema `public`) and refetches on any change. Errors are surfaced to the
/// stream so the UI can show a branded message.
final chatMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, otherUserId) {
  final user = SupabaseService.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  final controller = StreamController<List<Map<String, dynamic>>>();
  RealtimeChannel? channel;

  Future<void> fetchMessages() async {
    try {
      final roomId = await _findRoomId(user.id, otherUserId);
      if (roomId == null) {
        if (!controller.isClosed) controller.add([]);
        return;
      }

      final messages = await SupabaseService.client
          .from('chat_messages')
          .select()
          .eq('chatRoomId', roomId)
          .order('timestamp', ascending: true)
          .limit(200);

      if (!controller.isClosed) {
        controller.add(List<Map<String, dynamic>>.from(messages));
      }

      // Subscribe once the room id is known so we can scope the channel name.
      channel ??= SupabaseService.client
          .channel('chat_messages_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chatRoomId',
              value: roomId,
            ),
            callback: (_) => fetchMessages(),
          )
          .subscribe();
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  fetchMessages();

  ref.onDispose(() {
    controller.close();
    if (channel != null) {
      SupabaseService.client.removeChannel(channel!);
    }
  });

  return controller.stream;
});

/// Message actions notifier (send / edit / unsend).
class MessageActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  MessageActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Send a message to [receiverId], creating the room on first message.
  Future<bool> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      final trimmed = content.trim();
      if (trimmed.isEmpty) return false;

      // Block enforcement: refuse to send if either party has blocked the
      // other. This complements RLS and keeps blocked users from messaging.
      if (await isBlockRelation(receiverId)) return false;

      final now = DateTime.now().toIso8601String();

      // Resolve or create the shared room.
      var roomId = await _findRoomId(user.id, receiverId);
      if (roomId == null) {
        roomId = _directRoomId(user.id, receiverId);
        await SupabaseService.client.from('chat_rooms').upsert({
          'id': roomId,
          'type': 'direct',
          'participants': [user.id, receiverId],
          'lastMessage': trimmed,
          'lastMessageSenderId': user.id,
          'lastMessageAt': now,
          'lastUpdate': now,
          'unreadCount': {receiverId: 1},
        }, onConflict: 'id');
      } else {
        // Existing room: bump the RECEIVER's unread counter. Previously this
        // was only set when the room was first created, so the receiver never
        // saw an unread badge for any later message.
        Map<String, dynamic> unread = {};
        try {
          final row = await SupabaseService.client
              .from('chat_rooms')
              .select('unreadCount')
              .eq('id', roomId)
              .maybeSingle();
          final raw = row?['unreadCount'];
          if (raw is Map) unread = Map<String, dynamic>.from(raw);
        } catch (_) {}
        final current = unread[receiverId];
        final currentCount = current is num
            ? current.toInt()
            : (current is String ? int.tryParse(current) ?? 0 : 0);
        unread[receiverId] = currentCount + 1;

        await SupabaseService.client.from('chat_rooms').update({
          'lastMessage': trimmed,
          'lastMessageSenderId': user.id,
          'lastMessageAt': now,
          'lastUpdate': now,
          'unreadCount': unread,
        }).eq('id', roomId);
      }

      await SupabaseService.client.from('chat_messages').insert({
        'chatRoomId': roomId,
        'senderId': user.id,
        'text': trimmed,
        'type': 'text',
        'status': 'sent',
        'timestamp': now,
        'readBy': [user.id],
      });

      // Refresh the open chat immediately instead of relying on Realtime being
      // enabled for chat_messages (the chat screen watches the stream provider).
      ref.invalidate(chatMessagesProvider(receiverId));
      ref.invalidate(chatMessagesStreamProvider(receiverId));
      ref.invalidate(conversationsProvider);

      // If the receiver is an admin (support chat), ping them. No-op otherwise.
      AdminNotify.adminOfMessage(receiverId: receiverId, preview: trimmed);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mark the conversation with [otherUserId] as read.
  ///
  /// Resets the current user's unreadCount to 0 in the chat_rooms row,
  /// then refreshes conversationsProvider so the inbox dot disappears.
  Future<void> markConversationRead(String otherUserId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final roomId = await _findRoomId(user.id, otherUserId);
      if (roomId == null) return;

      // Fetch current unreadCount map and set our slot to 0.
      final room = await SupabaseService.client
          .from('chat_rooms')
          .select('unreadCount')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return;

      final unread = (room['unreadCount'] as Map?)?.cast<String, dynamic>() ?? {};
      if ((unread[user.id] ?? 0) == 0) return; // already read, skip update

      final updated = Map<String, dynamic>.from(unread);
      updated[user.id] = 0;

      await SupabaseService.client
          .from('chat_rooms')
          .update({'unreadCount': updated})
          .eq('id', roomId);

      ref.invalidate(conversationsProvider);
    } catch (_) {
      // Non-fatal — just means the badge may linger briefly.
    }
  }

  /// Edit a message previously sent by the current user.
  ///
  /// Requires non-empty content and the current user to be the sender. Sets
  /// `isEdited = true` and refreshes `updatedAt`. Returns `false` on any
  /// precondition violation or database failure.
  Future<bool> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      final trimmed = newContent.trim();
      if (trimmed.isEmpty) return false;

      final row = await SupabaseService.client
          .from('chat_messages')
          .select('senderId, chatRoomId, status')
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return false;

      final senderId = (row['senderId'] ?? '').toString();
      final status = (row['status'] ?? '').toString().toLowerCase();
      if (senderId != user.id) return false;
      if (status == 'deleted') return false;

      await SupabaseService.client.from('chat_messages').update({
        'text': trimmed,
        'isEdited': true,
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', messageId);

      _invalidateFromRoom((row['chatRoomId'] ?? '').toString(), user.id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Unsend a message previously sent by the current user.
  ///
  /// Sets `status = 'deleted'`, which the UI renders as an "unsent" placeholder
  /// for both participants. Only the sender may unsend.
  Future<bool> unsendMessage(String messageId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return false;

      final row = await SupabaseService.client
          .from('chat_messages')
          .select('senderId, chatRoomId')
          .eq('id', messageId)
          .maybeSingle();

      if (row == null) return false;

      final senderId = (row['senderId'] ?? '').toString();
      if (senderId != user.id) return false;

      await SupabaseService.client.from('chat_messages').update({
        'status': 'deleted',
        'text': '',
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', messageId);

      _invalidateFromRoom((row['chatRoomId'] ?? '').toString(), user.id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Invalidate the chat + conversation providers after a message change.
  ///
  /// The chat providers are keyed by the *other* participant's id, so we
  /// resolve it from the room's participants before invalidating.
  Future<void> _invalidateFromRoom(String roomId, String currentUserId) async {
    ref.invalidate(conversationsProvider);
    if (roomId.isEmpty) return;
    try {
      final room = await SupabaseService.client
          .from('chat_rooms')
          .select('participants')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return;
      final otherUserId = _otherParticipant(room, currentUserId);
      if (otherUserId != null && otherUserId.isNotEmpty) {
        ref.invalidate(chatMessagesProvider(otherUserId));
        ref.invalidate(chatMessagesStreamProvider(otherUserId));
      }
    } catch (_) {
      // Non-fatal: the conversations list refresh above still runs.
    }
  }
}

/// Message actions provider.
final messageActionsProvider =
    StateNotifierProvider<MessageActionsNotifier, AsyncValue<void>>((ref) {
  return MessageActionsNotifier(ref);
});


/// "Delete for me" for inbox conversations. Stored locally per user:
/// peerId -> marker time (the conversation's last_message_at when deleted).
/// The chat stays hidden until a newer message arrives, and only messages
/// after the marker are shown.
class HiddenChatsNotifier extends StateNotifier<Map<String, DateTime>> {
  final String? _uid;
  HiddenChatsNotifier(this._uid) : super(const {}) {
    _load();
  }

  String get _key => 'hidden_chats_${_uid ?? ''}';

  Future<void> _load() async {
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, DateTime>{};
      decoded.forEach((k, v) {
        final d = DateTime.tryParse(v.toString());
        if (d != null) map[k] = d;
      });
      state = {...map, ...state};
    } catch (_) {}
  }

  Future<void> hide(String peerId, DateTime marker) async {
    state = {...state, peerId: marker};
    if (_uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(state.map((k, v) => MapEntry(k, v.toIso8601String()))),
      );
    } catch (_) {}
  }
}

final hiddenChatsProvider =
    StateNotifierProvider<HiddenChatsNotifier, Map<String, DateTime>>((ref) {
  final uid = ref.watch(authProvider.select((a) => a.user?.id));
  return HiddenChatsNotifier(uid);
});

/// Conversations minus the ones the user deleted (until a newer message).
final visibleConversationsProvider =
    Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final hidden = ref.watch(hiddenChatsProvider);
  return ref.watch(conversationsProvider).whenData((list) {
    if (hidden.isEmpty) return list;
    return list.where((c) {
      final marker = hidden[c['other_user_id']?.toString()];
      if (marker == null) return true;
      final last = DateTime.tryParse((c['last_message_at'] ?? '').toString());
      return last != null && last.isAfter(marker);
    }).toList(growable: false);
  });
});
