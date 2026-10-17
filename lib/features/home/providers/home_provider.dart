import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/supabase_service.dart';

/// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Provider for featured campaigns (active, ordered by newest)
final featuredCampaignsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('campaigns')
        .select()
        .eq('status', 'active')
        .order('createdAt', ascending: false)
        .limit(30);

    return List<Map<String, dynamic>>.from(response)
        .where((row) => row['payout_model'] != 'job')
        .take(10)
        .toList();
  } catch (_) {
    return [];
  }
});

/// Provider for trending creators (ordered by followers desc)
final trendingCreatorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await SupabaseService.client
        .from('creator_profiles')
        .select('*, users!inner(name, profileImage, username, isVerified)') // live columns
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
          .order('createdAt', ascending: false)
          .limit(10);
      final fallbackRows = List<Map<String, dynamic>>.from(fallback);
      return fallbackRows.map((row) => <String, dynamic>{
        'users': {
          'name': row['name'],
          'profileImage': row['profileImage'],  // live: profileImage
          'username': row['username'],           // live: username
          'isVerified': row['isVerified'],
        },
        'followers': 0,
        'user_id': row['id'],
      }).toList();
    }

    return results;
  } catch (_) {
    return [];
  }
});

/// Provider for campaigns filtered by category
final filteredCampaignsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, category) async {
  var query = SupabaseService.client
      .from('campaigns')
      .select()
      .eq('status', 'active');

  if (category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query.order('createdAt', ascending: false).limit(40);

  return List<Map<String, dynamic>>.from(response)
      .where((row) => row['payout_model'] != 'job')
      .take(20)
      .toList();
});

/// Provider for recent campaigns (all active, paginated)
final recentCampaignsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);

  var query = SupabaseService.client
      .from('campaigns')
      .select()
      .eq('status', 'active');

  if (category != 'All') {
    query = query.eq('category', category);
  }

  final response = await query.order('createdAt', ascending: false).limit(40);

  return List<Map<String, dynamic>>.from(response)
      .where((row) => row['payout_model'] != 'job')
      .take(20)
      .toList();
});

/// Provider for current user profile data (for greeting)
final homeUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  return await SupabaseService.getUserProfile(user.id);
});


/// Notifier that persists bookmarked campaign ids to SharedPreferences.
class SavedCampaignsNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'saved_campaigns';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return Set<String>.from(list);
  }

  Future<void> toggle(String campaignId) async {
    final current = state.valueOrNull ?? {};
    final next = Set<String>.from(current);
    if (next.contains(campaignId)) {
      next.remove(campaignId);
    } else {
      next.add(campaignId);
    }
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isSaved(String campaignId) {
    return state.valueOrNull?.contains(campaignId) ?? false;
  }
}

final savedCampaignsProvider =
    AsyncNotifierProvider<SavedCampaignsNotifier, Set<String>>(
        SavedCampaignsNotifier.new);
