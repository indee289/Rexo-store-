/// Typed view model used by the messaging UI, parsed from a `messages` row.
///
/// Wraps the base message columns (`id`, `sender_id`, `receiver_id`, `content`,
/// `is_read`, `created_at`) together with the soft-state columns added by the
/// message soft-state migration (`is_unsent`, `edited_at`, `deleted_for`).
///
/// The [fromMap] factory is null-safe and tolerates legacy rows that predate
/// the soft-state migration: missing `is_unsent` defaults to `false`, missing
/// `edited_at` defaults to `null`, and missing `deleted_for` defaults to an
/// empty list.
///
/// See design "Data Models > Message model".
class MessageView {
  final String id;
  final String senderId;
  final String receiverId;

  /// The raw stored content. Prefer [displayContent] for rendering, which
  /// hides content for unsent messages.
  final String content;
  final bool isRead;
  final DateTime createdAt;

  // Soft-state fields.

  /// `true` when the sender unsent the message; content is hidden for everyone.
  final bool isUnsent;

  /// Non-null when the message was edited; presence means show an "edited" label.
  final DateTime? editedAt;

  /// User ids that have deleted this message for themselves (client filters).
  final List<String> deletedFor;

  const MessageView({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.isUnsent = false,
    this.editedAt,
    this.deletedFor = const [],
  });

  /// Displayed body: empty for unsent messages, otherwise the raw [content].
  ///
  /// Unsent bubbles render a "message unsent" placeholder and expose no actions.
  String get displayContent => isUnsent ? '' : content;

  /// Whether the message has been edited (presence of an edit timestamp).
  bool get isEdited => editedAt != null;

  /// Null-safe parse of a `messages` row into a [MessageView].
  ///
  /// Handles missing or legacy columns gracefully so rows created before the
  /// soft-state migration still parse:
  /// - `is_unsent` -> `false`
  /// - `edited_at` -> `null`
  /// - `deleted_for` -> `[]`
  factory MessageView.fromMap(Map<String, dynamic> map) {
    return MessageView(
      id: (map['id'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      isRead: _parseBool(map['is_read']),
      createdAt: _parseDate(map['created_at']),
      isUnsent: _parseBool(map['is_unsent']),
      editedAt: _parseNullableDate(map['edited_at']),
      deletedFor: _parseStringList(map['deleted_for']),
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

  /// Parses a list of user-id strings from a Postgres `uuid[]` value. Accepts a
  /// `List` (any element types) and defaults to an empty list otherwise.
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => e.toString())
          .toList(growable: false);
    }
    return const [];
  }
}

/// Returns the messages visible to [currentUserId], preserving the input's
/// ascending `createdAt` order.
///
/// A message is visible iff [currentUserId] is not present in its
/// `deletedFor` set. Unsent messages remain in the result (rendered as a
/// placeholder by the UI) unless the current user also deleted them for
/// themselves.
///
/// Pure function: does not mutate [all]; the returned list is a new list.
///
/// See design "Key Functions > visibleMessages" and "Algorithmic Pseudocode".
List<MessageView> visibleMessages(List<MessageView> all, String currentUserId) {
  final result = <MessageView>[];
  for (final m in all) {
    // Invariant: result holds all not-deleted-for-me messages seen so far,
    // in original order.
    if (!m.deletedFor.contains(currentUserId)) {
      result.add(m);
    }
  }
  return result;
}
