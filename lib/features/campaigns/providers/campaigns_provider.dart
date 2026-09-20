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

  // Fetch active campaigns (SELECT * works through PostgREST). Job rows are
  // excluded in Dart because filtering .neq('payout_model',...) server-side
  // fails on this project's schema cache.
  var query = SupabaseService.client
      .from('campaigns')
      .select('*, users!brandId(id, name, profileImage)'); // live FK: brandId (camelCase)

  if (category != 'All') {
    query = query.eq('category', category);
  }

  if (searchTerm.isNotEmpty) {
    query = query.ilike('title', '%$searchTerm%');
  }

  final response = await query.order('createdAt', ascending: false).limit(100); // live: createdAt

  return List<Map<String, dynamic>>.from(response)
      .where((row) => row['payout_model'] != 'job')
      .take(50)
      .toList();
});

/// Provider for single campaign detail with brand info
final campaignDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select('*, users!brandId(id, name, profileImage)') // live FK: brandId (camelCase)
      .eq('id', id)
      .maybeSingle();

  // Not a real campaign if it's a job row.
  if (response != null && response['payout_model'] == 'job') return null;
  return response;
});

/// Provider for current user's applications
final myApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // Fetch applications with campaignId, then enrich with campaign data separately
  // (embedded join campaigns(*) fails because FK column is camelCase campaignId)
  final response = await SupabaseService.client
      .from('applications')
      .select()
      .eq('creatorId', user.id)
      .order('createdAt', ascending: false); // live: createdAt

  final rows = List<Map<String, dynamic>>.from(response);
  final result = <Map<String, dynamic>>[];

  for (final row in rows) {
    final campaignId = row['campaignId'] as String?;
    if (campaignId == null) continue;

    try {
      final campaign = await SupabaseService.client
          .from('campaigns')
          .select()
          .eq('id', campaignId)
          .maybeSingle();
      if (campaign == null) continue;
      if (campaign['payout_model'] == 'job' || campaign['payoutModel'] == 'job') continue;
      result.add({...row, 'campaigns': campaign});
    } catch (_) {}
  }
  return result;
});

/// Provider for the current user's applied campaigns (drives the Campaigns tab).
///
/// Returns the campaigns the current user has applied to, newest application
/// first. Each entry is the full campaign row (including `cover_image_url` and
/// the joined `users` brand row via `users!brand_id`) augmented with two
/// application fields:
///
/// - `application_status`: the application's `status` (pending/approved/rejected)
/// - `applied_at`: the application's `created_at` timestamp
///
/// Returns an empty list when signed out. Rows whose joined campaign is null
/// (e.g. the campaign was deleted) are skipped so the UI never renders a card
/// without a campaign.
final appliedCampaignsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  // Fetch applications then enrich with campaign data separately
  // (PostgREST can't auto-join via camelCase FK campaignId)
  final response = await SupabaseService.client
      .from('applications')
      .select()
      .eq('creatorId', user.id)
      .order('createdAt', ascending: false); // live: createdAt

  final rows = List<Map<String, dynamic>>.from(response);
  final result = <Map<String, dynamic>>[];

  for (final row in rows) {
    final campaignId = row['campaignId'] as String?;
    if (campaignId == null) continue;

    try {
      final campaign = await SupabaseService.client
          .from('campaigns')
          .select('*, users!brandId(id, name, profileImage)')
          .eq('id', campaignId)
          .maybeSingle();
      if (campaign == null) continue;
      if (campaign['payout_model'] == 'job' || campaign['payoutModel'] == 'job') continue;

      result.add({
        ...campaign,
        'application_status': row['status'],
        'applied_at': row['createdAt'] ?? row['created_at'],
      });
    } catch (_) {}
  }

  return result;
});

/// Campaign actions notifier for applying to campaigns
class CampaignActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  CampaignActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Apply to a campaign.
  ///
  /// The extra creator-profile fields (name, location, category, city, state,
  /// contact number, Instagram link, followers) are persisted on the
  /// applications row (see supabase/add_application_fields.sql) so the campaign
  /// poster can review a full applicant profile from their dashboard.
  Future<bool> applyToCampaign({
    required String campaignId,
    required String pitch,
    required String portfolioUrl,
    String? applicantName,
    String? location,
    String? category,
    String? city,
    String? state,
    String? contactNumber,
    String? instagramUrl,
    int? followersCount,
  }) async {
    this.state = const AsyncValue.loading();

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        this.state =
            AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('applications').insert({
        'campaignId': campaignId,    // live: camelCase
        'creatorId': user.id,        // live: camelCase
        'pitch': pitch,
        'portfolio_url': portfolioUrl,
        'applicant_name': applicantName,
        'location': location,
        'category': category,
        'city': city,
        'state': state,
        'contact_number': contactNumber,
        'instagram_url': instagramUrl,
        'followers_count': followersCount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      this.state = const AsyncValue.data(null);

      // Invalidate applications provider to refresh
      ref.invalidate(myApplicationsProvider);

      return true;
    } catch (e, st) {
      this.state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Campaign actions provider
final campaignActionsProvider =
    StateNotifierProvider<CampaignActionsNotifier, AsyncValue<void>>((ref) {
  return CampaignActionsNotifier(ref);
});

/// Applicants for a given campaign, for the brand (campaign poster) dashboard.
///
/// Joins each application with the creator's public user row so the poster can
/// see who applied. RLS ("Brands can read applications for their campaigns")
/// restricts this to the campaign owner (and admins). Ordered newest-first.
final campaignApplicantsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (ref, campaignId) async {
  final response = await SupabaseService.client
      .from('applications')
      .select(
          '*, creator:users!creatorId(id, name, username, profileImage, isVerified)') // live columns
      .eq('campaignId', campaignId)   // live: camelCase
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// Current user's own profile row (used to prefill the Apply form). Named
/// distinctly from the profile feature's provider to avoid any import clash.
/// Returns null when signed out or the profile row is missing.
final applyPrefillProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;
  return SupabaseService.getUserProfile(user.id);
});

/// Check if user has already applied to a specific campaign
final hasAppliedProvider = FutureProvider.family<bool, String>((ref, campaignId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('campaignId', campaignId)   // live: camelCase
      .eq('creatorId', user.id)       // live: camelCase
      .maybeSingle();

  return response != null;
});
