/// Typed view model used by the messaging UI, parsed from a `chat_messages`
/// row (the live table).
///
/// The live `chat_messages` table uses camelCase columns:
///   id (uuid), chatRoomId (text), senderId (text), text (the body),
///   type (text), imageUrl (text), status (text), timestamp (created-at),
///   readBy (jsonb), isEdited (bool), updatedAt (timestamptz), reactions (jsonb)
///
/// There is no dedicated `is_unsent` column, so an unsent message is modeled by
/// `status == 'deleted'`. The [fromMap] factory is null-safe and also tolerates
/// the legacy `messages`-table field names (`sender_id`, `content`, `is_read`,
/// `created_at`) so nothing breaks if an older row shape ever appears.
class MessageView {
  final String id;
  final String senderId;

  /// The raw stored body. Prefer [displayContent] for rendering, which hides
  /// content for unsent messages.
  final String content;
  final bool isRead;
  final DateTime createdAt;

  /// `true` when the message was unsent (`chat_messages.status == 'deleted'`);
  /// the body is hidden for everyone.
  final bool isUnsent;

  /// `true` when the message was edited (`chat_messages.isEdited`); presence
  /// means the UI shows an "edited" label.
  final bool isEdited;

  const MessageView({
    required this.id,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.isUnsent = false,
    this.isEdited = false,
  });

  /// Displayed body: empty for unsent messages, otherwise the raw [content].
  String get displayContent => isUnsent ? '' : content;

  /// Null-safe parse of a `chat_messages` row (with legacy fallbacks) into a
  /// [MessageView].
  factory MessageView.fromMap(Map<String, dynamic> map) {
    final status = (map['status'] ?? '').toString().toLowerCase();
    return MessageView(
      id: (map['id'] ?? '').toString(),
      senderId: (map['senderId'] ?? map['sender_id'] ?? '').toString(),
      content: (map['text'] ?? map['content'] ?? '').toString(),
      isRead: _parseBool(map['is_read']) || status == 'read' || status == 'seen',
      createdAt: _parseDate(map['timestamp'] ?? map['created_at']),
      isUnsent: status == 'deleted' || _parseBool(map['is_unsent']),
      isEdited: _parseBool(map['isEdited']) || map['edited_at'] != null,
    );
  }

  /// Parses a `bool` from dynamic input (bool, "true"/"false", 1/0). Defaults
  /// to `false` for null or unrecognized values.
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == 't' || v == '1';
    }
    return false;
  }

  /// Parses a required `DateTime`, falling back to the epoch on failure so
  /// parsing never throws for malformed/missing timestamps.
  static DateTime _parseDate(dynamic value) {
    return _parseNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Parses an optional `DateTime`; returns `null` for null/blank/invalid input.
  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return DateTime.tryParse(str);
  }
}

/// Returns the messages visible to [currentUserId], preserving the input's
/// ascending `createdAt` order.
///
/// With the live `chat_messages` schema there is no per-user "delete for me"
/// column, so every message is visible to both participants. Unsent messages
/// remain in the result (rendered as a placeholder by the UI). This function is
/// kept for the chat screen's call site and to leave room for future per-user
/// hiding without touching the widget layer.
///
/// Pure function: does not mutate [all]; the returned list is a new list.
List<MessageView> visibleMessages(List<MessageView> all, String currentUserId) {
  return List<MessageView>.of(all);
}
