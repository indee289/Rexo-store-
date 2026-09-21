/// Normalized creator shape consumed by the Instagram-style creator profile
/// (see design "Data Models > Creator lookup model (resilient)").
///
/// A creator may exist as a full `creator_profiles` row (joined with its
/// `users` row) or only as a plain `users` row (the Top Creators fallback
/// path). Both shapes normalize to this single view so the profile screen can
/// render without a "creator not found" error.
///
/// The [fromCreatorProfileRow] / [fromUserRow] factories are null-safe and
/// supply defaults (empty [category]/[bio], zero [rating]/[campaignsCompleted])
/// when a creator has no `creator_profiles` row.
class CreatorView {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String handle;
  final bool isVerified;

  /// Creator category; `''` when there is no `creator_profiles` row.
  final String category;

  /// Creator bio; `''` when none.
  final String bio;

  /// Rating; `0.0` when there is no `creator_profiles` row.
  final double rating;

  /// Completed campaigns; `0` when there is no `creator_profiles` row.
  final int campaignsCompleted;

  const CreatorView({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.handle,
    required this.isVerified,
    this.category = '',
    this.bio = '',
    this.rating = 0.0,
    this.campaignsCompleted = 0,
  });

  /// Builds a [CreatorView] from a `creator_profiles` row joined with its
  /// `users` row (nested under the `users` key).
  ///
  /// Category, rating, and completed-campaign values come from the
  /// creator-profile columns (`category`, `rating`, `completed_campaigns`);
  /// identity fields come from the nested `users` object. Missing values fall
  /// back to the defaults.
  factory CreatorView.fromCreatorProfileRow(Map<String, dynamic> row) {
    final user = _asMap(row['users']);
    return CreatorView(
      userId: (user['id'] ?? row['user_id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      avatarUrl: _asNullableString(user['profileImage']),  // live: profileImage
      handle: (user['username'] ?? '').toString(),          // live: username
      isVerified: _parseBool(user['isVerified']),
      category: (row['category'] ?? '').toString(),
      bio: (user['bio'] ?? '').toString(),
      rating: _parseDouble(row['rating']),
      campaignsCompleted: _parseInt(row['completed_campaigns']),
    );
  }

  /// Builds a [CreatorView] from a plain `users` row (the fallback path used
  /// when no `creator_profiles` row exists).
  ///
  /// Creator-profile-specific fields default to empty/zero: [category] `''`,
  /// [bio] from the user row, [rating] `0.0`, [campaignsCompleted] `0`.
  factory CreatorView.fromUserRow(Map<String, dynamic> user) {
    return CreatorView(
      userId: (user['id'] ?? '').toString(),
      name: (user['name'] ?? '').toString(),
      avatarUrl: _asNullableString(user['profileImage']),  // live: profileImage
      handle: (user['username'] ?? '').toString(),          // live: username
      isVerified: _parseBool(user['isVerified']),
      category: '',
      bio: (user['bio'] ?? '').toString(),
      rating: 0.0,
      campaignsCompleted: 0,
    );
  }

  /// Coerces a dynamic value into a `Map<String, dynamic>`; returns an empty
  /// map for null or non-map input so nested access never throws.
  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  /// Returns a trimmed non-empty string, or `null` for null/blank input.
  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  /// Parses a `bool` from dynamic input (bool, 1/0, "true"/"false"). Defaults
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

  /// Parses a `double` from dynamic input (num or numeric string). Defaults to
  /// `0.0` for null or unparseable values.
  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0.0;
    return 0.0;
  }

  /// Parses an `int` from dynamic input (num or numeric string). Defaults to
  /// `0` for null or unparseable values.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ??
          double.tryParse(value.trim())?.toInt() ??
          0;
    }
    return 0;
  }
}
