import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// The kind of entity being reported. Maps to moderation_queue.content_type.
enum ReportTargetType { user, campaign, message }

extension ReportTargetTypeX on ReportTargetType {
  String get value {
    switch (this) {
      case ReportTargetType.user:
        return 'user';
      case ReportTargetType.campaign:
        return 'campaign';
      case ReportTargetType.message:
        return 'message';
    }
  }

  String get label {
    switch (this) {
      case ReportTargetType.user:
        return 'user';
      case ReportTargetType.campaign:
        return 'campaign';
      case ReportTargetType.message:
        return 'message';
    }
  }
}

/// Canonical report reasons shown in the UI.
const List<String> kReportReasons = [
  'Spam',
  'Harassment',
  'Scam or Fraud',
  'Inappropriate content',
  'Impersonation',
  'Copyright',
  'Other',
];

/// Submits reports into the existing `moderation_queue` table.
///
/// The reporter identity is the authenticated user (reported_by = auth.uid());
/// RLS enforces that a user can only insert rows as themselves.
class ReportNotifier extends StateNotifier<AsyncValue<String?>> {
  ReportNotifier() : super(const AsyncValue.data(null));

  /// Returns the created report id on success, or throws on failure.
  Future<String> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw StateError('You must be signed in to report.');
      }

      final trimmedDetails = details?.trim();
      final inserted = await SupabaseService.client
          .from('moderation_queue')
          .insert({
            'content_id': targetId,
            'content_type': targetType.value,
            'reported_by': user.id,
            'reason': reason,
            if (trimmedDetails != null && trimmedDetails.isNotEmpty)
              'details': trimmedDetails,
            'status': 'pending',
          })
          .select('id')
          .single();

      final reportId = (inserted['id'] ?? '').toString();
      state = AsyncValue.data(reportId);
      return reportId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<String?>>(
  (ref) => ReportNotifier(),
);

/// The current user's own submitted reports (transparency). RLS restricts this
/// to rows where reported_by = auth.uid().
final myReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];
  try {
    final rows = await SupabaseService.client
        .from('moderation_queue')
        .select('id, content_type, reason, status, created_at')
        .eq('reported_by', user.id)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  } catch (_) {
    return [];
  }
});
