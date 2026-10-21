import 'package:flutter/foundation.dart';

import '../../services/supabase_service.dart';

/// Best-effort helpers that make sure the admin SEES what users submit.
///
/// A normal user is blocked by RLS from writing notification rows for other
/// people, so these call SECURITY DEFINER RPCs defined in
/// supabase/CAMPSTER_ADMIN_REQUESTS_FIX.sql. They never throw: the user's own
/// action (dispute, withdrawal, ...) has already succeeded and must not be
/// reported as failed just because the admin ping could not be delivered.
class AdminNotify {
  AdminNotify._();

  /// Put an in-app notification in every admin's notification list.
  static Future<void> admins({
    required String title,
    required String message,
    String type = 'admin_request',
  }) async {
    try {
      await SupabaseService.client.rpc('notify_admins', params: {
        'p_title': title,
        'p_message': message,
        'p_type': type,
      });
    } catch (e) {
      debugPrint('AdminNotify.admins skipped: $e');
    }
  }

  /// Notify [receiverId] about a chat message — only has an effect when the
  /// receiver is an admin (enforced server-side).
  static Future<void> adminOfMessage({
    required String receiverId,
    required String preview,
  }) async {
    try {
      await SupabaseService.client.rpc('notify_admin_of_message', params: {
        'p_receiver': receiverId,
        'p_preview': preview,
      });
    } catch (e) {
      debugPrint('AdminNotify.adminOfMessage skipped: $e');
    }
  }

  /// User id of an admin the Help screen can open a chat with, or null.
  static Future<String?> supportAdminId() async {
    final self = SupabaseService.currentUser?.id;
    try {
      final res = await SupabaseService.client.rpc('get_support_admin');
      final id = res?.toString() ?? '';
      if (id.isNotEmpty && id != 'null' && id != self) return id;
    } catch (e) {
      debugPrint('get_support_admin RPC unavailable: $e');
    }
    // Fallback when the SQL has not been run yet: read it straight from users
    // (works only if users SELECT RLS allows it).
    try {
      final rows = await SupabaseService.client
          .from('users')
          .select('uid, role')
          .ilike('role', 'admin')
          .limit(5);
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final id = (r['uid'] ?? '').toString();
        if (id.isNotEmpty && id != self) return id;
      }
    } catch (e) {
      debugPrint('support admin lookup failed: $e');
    }
    return null;
  }
}
