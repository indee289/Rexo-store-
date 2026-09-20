import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Provider for featured campaigns (active, ordered by newest)
final featuredCampaignsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select()
      .eq('status', 'active')
      .eq('is_job', false)
      .order('created_at', ascending: false)
      .limit(10);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for trending creators (ordered by followers desc)
final trendingCreatorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('creator_profiles')
      .select('*, users!inner(name, avatar_url, handle, is_verified)')
      .order('followers', ascending: false)
      .limit(10);

  final results = List<Map<String, dynamic>>.from(response);

  // Fallback: if no creator_profiles exist, fetch users with role='creator'
  // and normalize shape to match the primary query's nested structure
  if (results.isEmpty) {
    final fallback = await SupabaseService.client
        .from('users')
        .select()
        .eq('role', 'creator')
        .order('created_at', ascending: false)
        .limit(10);
    final fallbackRows = List<Map<String, dynamic>>.from(fallback);
    return fallbackRows.map((row) => <String, dynamic>{
      'users': {
        'name': row['name'],
        'avatar_url': row['avatar_url'],
        'handle': row['handle'],
        'is_verified': row['is_verified'],
      },
      'followers': 0,
      'user_id': row['id'],
    }).toList();
  }

  return results;
});

/// Provider for campaigns filtered by category
final filteredCampaignsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) async {
  var query = SupabaseService.client
      .from('campaigns')
      .select()
      .eq('status', 'active')
      .eq('is_job', false);

  if (category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query.order('created_at', ascending: false).limit(20);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for recent campaigns (all active, paginated)
final recentCampaignsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);

  var query = SupabaseService.client
      .from('campaigns')
      .select()
      .eq('status', 'active')
      .eq('is_job', false);

  if (category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query.order('created_at', ascending: false).limit(20);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for current user profile data (for greeting)
final homeUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  return await SupabaseService.getUserProfile(user.id);
});


/// Local (in-memory) set of bookmarked/saved campaign ids for the Home screen.
/// Toggled by the bookmark icon on each featured campaign card. Kept in
/// Riverpod so the saved state survives rebuilds without extra dependencies.
final savedCampaignsProvider =
    StateProvider<Set<String>>((ref) => <String>{});
