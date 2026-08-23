import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Filter provider for campaign category
final campaignFilterProvider = StateProvider<String>((ref) => 'All');

/// Search term provider
final campaignSearchProvider = StateProvider<String>((ref) => '');

/// Provider for all active campaigns list
final campaignsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(campaignFilterProvider);
  final searchTerm = ref.watch(campaignSearchProvider);

  var query = SupabaseService.client
      .from('campaigns')
      .select('*, users!brand_id(id, name, avatar_url)')
      .eq('status', 'active');

  if (category != 'All') {
    query = query.eq('category', category);
  }

  if (searchTerm.isNotEmpty) {
    query = query.ilike('title', '%$searchTerm%');
  }

  final response = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Provider for single campaign detail with brand info
final campaignDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select('*, users!brand_id(id, name, avatar_url)')
      .eq('id', id)
      .maybeSingle();

  return response;
});

/// Provider for current user's applications
final myApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final response = await SupabaseService.client
      .from('applications')
      .select('*, campaigns(id, title, status)')
      .eq('creator_id', user.id)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Campaign actions notifier for applying to campaigns
class CampaignActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  CampaignActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Apply to a campaign
  Future<bool> applyToCampaign({
    required String campaignId,
    required String pitch,
    required String portfolioUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('applications').insert({
        'campaign_id': campaignId,
        'creator_id': user.id,
        'pitch': pitch,
        'portfolio_url': portfolioUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = const AsyncValue.data(null);

      // Invalidate applications provider to refresh
      ref.invalidate(myApplicationsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Campaign actions provider
final campaignActionsProvider =
    StateNotifierProvider<CampaignActionsNotifier, AsyncValue<void>>((ref) {
  return CampaignActionsNotifier(ref);
});

/// Check if user has already applied to a specific campaign
final hasAppliedProvider = FutureProvider.family<bool, String>((ref, campaignId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('campaign_id', campaignId)
      .eq('creator_id', user.id)
      .maybeSingle();

  return response != null;
});
