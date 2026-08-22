import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Filter type for security logs
enum SecurityLogFilter { all, logins, suspicious }

/// Provider for the active filter
final securityLogFilterProvider = StateProvider<SecurityLogFilter>((ref) {
  return SecurityLogFilter.all;
});

/// Fetch security logs for the current user
final securityLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = SupabaseService.currentUser?.id;
  if (userId == null) return [];

  final filter = ref.watch(securityLogFilterProvider);

  var query = SupabaseService.client
      .from('security_logs')
      .select()
      .eq('user_id', userId);

  switch (filter) {
    case SecurityLogFilter.logins:
      query = query.inFilter('event_type', ['login', 'failed_login']);
      break;
    case SecurityLogFilter.suspicious:
      query = query.eq('is_suspicious', true);
      break;
    case SecurityLogFilter.all:
      break;
  }

  final response = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});
