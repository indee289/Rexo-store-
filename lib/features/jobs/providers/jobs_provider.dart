import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ─── Filter / Search State ────────────────────────────────────────────────────

/// Active category filter on the Available Jobs tab ('All' = no filter).
final jobCategoryFilterProvider = StateProvider<String>((ref) => 'All');

/// Search term on the Available Jobs tab.
final jobSearchProvider = StateProvider<String>((ref) => '');

/// Status filter on My Jobs tab.
final myJobsStatusFilterProvider = StateProvider<String>((ref) => 'all');

// ─── Column Mapping Helper ────────────────────────────────────────────────────
//
// Jobs are stored as rows in the ALREADY-CACHED `campaigns` table tagged
// `is_job = true` (PostgREST refuses to serve the standalone `jobs` table with
// PGRST205, but campaigns is served perfectly). This helper maps a raw
// campaigns row back into the job-shaped map the Jobs screens expect.
//
// Mapping convention (must match supabase/JOBS_VIA_CAMPAIGNS.sql exactly):
//   payment_amount <- payout_per_creator
//   max_slots      <- total_slots, where total_slots == 0 means "unlimited"
//                     and is exposed back as max_slots = null.
//   title/description/category/deadline/cover_image_url/status/id/created_at/
//   updated_at pass through unchanged.
// The original campaigns columns are kept in the map too so nothing else breaks.
Map<String, dynamic> _mapCampaignToJob(Map<String, dynamic> row) {
  final totalSlots = row['slots'];
  final maxSlots = (totalSlots is num && totalSlots.toInt() == 0)
      ? null
      : totalSlots;

  return {
    ...row,
    'payment_amount': row['payout_per_creator'],
    'max_slots': maxSlots,
    // Expose the live cover_image column under the key the job cards read.
    'cover_image_url': row['cover_image'],
    // created_by mirrors the campaigns.brand_id used on create.
    'created_by': row['brand_id'],
  };
}

// ─── Available Jobs ───────────────────────────────────────────────────────────

/// All active jobs, filtered by category + search term.
final availableJobsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(jobCategoryFilterProvider);
  final search = ref.watch(jobSearchProvider);

  var query = SupabaseService.client
      .from('campaigns')
      .select()
      .eq('is_job', true)
      .eq('status', 'active');

  if (category != 'All') {
    query = query.eq('category', category);
  }

  if (search.isNotEmpty) {
    query = query.ilike('title', '%$search%');
  }

  final response = await query.order('created_at', ascending: false).limit(100);
  return List<Map<String, dynamic>>.from(response)
      .map(_mapCampaignToJob)
      .toList();
});

/// Distinct categories derived from existing active jobs (dynamic, no hardcode).
final jobCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final jobs = await SupabaseService.client
      .from('campaigns')
      .select('category')
      .eq('is_job', true)
      .eq('status', 'active');

  final cats = <String>{};
  for (final row in List<Map<String, dynamic>>.from(jobs)) {
    final cat = row['category'] as String?;
    if (cat != null && cat.trim().isNotEmpty) cats.add(cat.trim());
  }
  final sorted = cats.toList()..sort();
  return ['All', ...sorted];
});

/// Slot counts for a single job: returns { filled: int }.
final jobSlotCountProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, jobId) async {
  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('campaign_id', jobId)
      .inFilter('status', ['applied', 'submitted', 'approved']);

  final filled = (response as List).length;
  return {'filled': filled};
});

// ─── Job Detail ───────────────────────────────────────────────────────────────

/// Single job detail.
final jobDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, jobId) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select()
      .eq('id', jobId)
      .eq('is_job', true)
      .maybeSingle();
  if (response == null) return null;
  return _mapCampaignToJob(Map<String, dynamic>.from(response));
});

/// Whether the current user has already applied to a specific job.
final hasAppliedToJobProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, jobId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('campaign_id', jobId)
      .eq('creator_id', user.id)
      .maybeSingle();

  return response != null;
});

// ─── My Jobs ─────────────────────────────────────────────────────────────────

/// The current user's job applications, joined with the job details.
/// Optionally filtered by status (pass 'all' for no filter).
final myJobApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final statusFilter = ref.watch(myJobsStatusFilterProvider);

  var query = SupabaseService.client
      .from('applications')
      .select()
      .eq('creator_id', user.id);

  if (statusFilter != 'all') {
    query = query.eq('status', statusFilter);
  }

  final response = await query.order('created_at', ascending: false);
  final rows = List<Map<String, dynamic>>.from(response);

  // Fetch each job (campaign) separately (avoids embedded-join RLS/PGRST issues)
  final enriched = <Map<String, dynamic>>[];
  for (final row in rows) {
    final campaignId = row['campaign_id'] as String?;
    Map<String, dynamic>? jobRow;
    if (campaignId != null) {
      try {
        final campaign = await SupabaseService.client
            .from('campaigns')
            .select()
            .eq('id', campaignId)
            .eq('is_job', true)
            .maybeSingle();
        if (campaign != null) {
          jobRow = _mapCampaignToJob(Map<String, dynamic>.from(campaign));
        }
      } catch (_) {}
    }

    // Safety net: the shared `applications` table also holds real campaign
    // applications (whose campaign_id points at an is_job=false campaign). For
    // those the is_job fetch above returns null; skip them so they never render
    // as phantom "Untitled Job" / ₹0 cards under the all/approved/rejected
    // filters. Mirrors adminJobSubmissionsProvider's `if (jobRow == null)`.
    if (jobRow == null) continue;

    enriched.add({
      ...row,
      // Expose the keys the screen reads at row level and the aliases that
      // legacy code referenced (job_id / applied_at).
      'job_id': campaignId,
      'applied_at': row['created_at'],
      'jobs': jobRow,
    });
  }
  return enriched;
});

// ─── Admin Providers ──────────────────────────────────────────────────────────

/// All jobs for the admin manage list (all statuses).
final adminJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('campaigns')
      .select()
      .eq('is_job', true)
      .order('created_at', ascending: false)
      .limit(200);
  return List<Map<String, dynamic>>.from(response)
      .map(_mapCampaignToJob)
      .toList();
});

/// Applicant count per job (used in admin list).
final adminJobApplicantCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, jobId) async {
  final response = await SupabaseService.client
      .from('applications')
      .select('id')
      .eq('campaign_id', jobId);
  return (response as List).length;
});

/// All submitted (pending review) job applications for admin review.
final adminJobSubmissionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('applications')
      .select()
      .eq('status', 'submitted')
      .order('created_at', ascending: false)
      .limit(200);
  final rows = List<Map<String, dynamic>>.from(response);

  // Fetch job (campaign) + user details separately to avoid embedded-join
  // failures, and use the campaign fetch as an is_job safety net: real
  // campaign applications never carry status 'submitted', but skip any row
  // whose parent campaign is not a job anyway.
  final enriched = <Map<String, dynamic>>[];
  for (final row in rows) {
    final userId = row['creator_id'] as String?;
    final campaignId = row['campaign_id'] as String?;

    Map<String, dynamic>? jobRow;
    if (campaignId != null) {
      try {
        final campaign = await SupabaseService.client
            .from('campaigns')
            .select('id, title, payout_per_creator, is_job')
            .eq('id', campaignId)
            .maybeSingle();
        if (campaign != null && campaign['is_job'] == true) {
          jobRow = _mapCampaignToJob(Map<String, dynamic>.from(campaign));
        }
      } catch (_) {}
    }

    // Safety net: skip rows whose campaign is not a job (is_job != true).
    if (jobRow == null) continue;

    Map<String, dynamic>? userRow;
    if (userId != null) {
      try {
        userRow = await SupabaseService.client
            .from('users')
            .select('id, name, handle, avatar_url')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {}
    }

    enriched.add({...row, 'users': userRow ?? {}, 'jobs': jobRow});
  }
  return enriched;
});

// ─── Jobs Actions Notifier ────────────────────────────────────────────────────

class JobsActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  JobsActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  // ── User Actions ──────────────────────────────────────────────────────────

  /// Apply to a job.
  ///
  /// Slot caps are enforced server-side by the enforce_job_slots BEFORE INSERT
  /// trigger on public.applications (see supabase/JOBS_VIA_CAMPAIGNS.sql), which
  /// fires only for is_job campaigns. Duplicate applies are prevented by the
  /// UNIQUE(campaign_id, creator_id) constraint on applications and gated in the
  /// UI by hasAppliedToJobProvider; a second apply throws, which the catch below
  /// converts into a returned false + error state.
  Future<bool> applyToJob(String jobId) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      final now = DateTime.now().toIso8601String();
      await SupabaseService.client.from('applications').insert({
        'campaign_id': jobId,
        'creator_id': user.id,
        'status': 'applied',
        'created_at': now,
        'updated_at': now,
      });

      state = const AsyncValue.data(null);
      ref.invalidate(myJobApplicationsProvider);
      ref.invalidate(hasAppliedToJobProvider(jobId));
      ref.invalidate(availableJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Submit proof for an applied job (moves status → submitted).
  Future<bool> submitTask({
    required String applicationId,
    required String submissionType,
    required String submissionUrl,
    String? submissionNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.client.from('applications').update({
        'status': 'submitted',
        'submission_type': submissionType,
        'submission_url': submissionUrl,
        'submission_note': submissionNote,
        'submitted_at': now,
        'updated_at': now,
      }).eq('id', applicationId);

      state = const AsyncValue.data(null);
      ref.invalidate(myJobApplicationsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // ── Admin Actions ─────────────────────────────────────────────────────────

  /// Create a new job posting.
  ///
  /// Incoming [data] keys: title, description, category, payment_amount,
  /// max_slots(nullable), deadline(nullable ISO), cover_image_url(nullable).
  /// These are translated to campaigns columns; the raw payment_amount/
  /// max_slots keys are NOT written (they are not campaigns columns).
  Future<bool> createJob(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      final now = DateTime.now().toIso8601String();
      await SupabaseService.client.from('campaigns').insert({
        'title': data['title'],
        'description': data['description'],
        'category': data['category'],
        'payout_per_creator': data['payment_amount'],
        // Convention: null max_slots -> slots = 0 ("unlimited").
        'slots': data['max_slots'] ?? 0,
        'deadline': data['deadline'],
        'cover_image': data['cover_image_url'],
        'is_job': true,
        'brand_id': user.id,
        // brandName is NOT NULL with no default on the live campaigns table,
        // so every insert must supply it. Jobs are platform-posted, so use a
        // fixed label (the job title also carries the real name).
        'brandName': 'Rexo',
        'status': 'active',
        'budget': 0,
        'created_at': now,
        'updated_at': now,
      });

      state = const AsyncValue.data(null);
      ref.invalidate(adminJobsProvider);
      ref.invalidate(availableJobsProvider);
      ref.invalidate(jobCategoriesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update an existing job.
  Future<bool> updateJob(String jobId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      // Translate the job-shaped keys into campaigns columns. Only pass through
      // keys that are actually present in the incoming data map.
      final update = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (data.containsKey('title')) update['title'] = data['title'];
      if (data.containsKey('description')) {
        update['description'] = data['description'];
      }
      if (data.containsKey('category')) update['category'] = data['category'];
      if (data.containsKey('deadline')) update['deadline'] = data['deadline'];
      if (data.containsKey('cover_image_url')) {
        update['cover_image'] = data['cover_image_url'];
      }
      if (data.containsKey('status')) update['status'] = data['status'];
      if (data.containsKey('payment_amount')) {
        update['payout_per_creator'] = data['payment_amount'];
      }
      if (data.containsKey('max_slots')) {
        // Convention: null max_slots -> total_slots = 0 ("unlimited").
        update['slots'] = data['max_slots'] ?? 0;
      }

      await SupabaseService.client
          .from('campaigns')
          .update(update)
          .eq('id', jobId);

      state = const AsyncValue.data(null);
      ref.invalidate(adminJobsProvider);
      ref.invalidate(availableJobsProvider);
      ref.invalidate(jobDetailProvider(jobId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Toggle job status between active and closed.
  Future<bool> toggleJobStatus(String jobId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'closed' : 'active';
    return updateJob(jobId, {'status': newStatus});
  }

  /// Hard-delete a job (cascades to its applications via ON DELETE CASCADE).
  Future<bool> deleteJob(String jobId) async {
    state = const AsyncValue.loading();
    try {
      // Guard on is_job so a real campaign can never be hard-deleted through
      // the jobs path (which would cascade-delete its applications).
      await SupabaseService.client
          .from('campaigns')
          .delete()
          .eq('id', jobId)
          .eq('is_job', true);

      state = const AsyncValue.data(null);
      ref.invalidate(adminJobsProvider);
      ref.invalidate(availableJobsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Approve a job submission:
  /// 1. Update application → approved + reviewed_at + reviewed_by
  /// 2. Credit user wallet via atomic RPC
  /// 3. Insert in-app notification for the user
  Future<bool> approveJobSubmission(String applicationId) async {
    state = const AsyncValue.loading();
    try {
      final admin = SupabaseService.currentUser;
      if (admin == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      // Fetch application to get creator_id and campaign_id, then campaign
      // (job) separately.
      final app = await SupabaseService.client
          .from('applications')
          .select('creator_id, campaign_id')
          .eq('id', applicationId)
          .maybeSingle();

      if (app == null) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final userId = app['creator_id'] as String;
      final jobId = app['campaign_id'] as String;
      final job = await SupabaseService.client
          .from('campaigns')
          .select('title, payout_per_creator')
          .eq('id', jobId)
          .maybeSingle();
      final jobTitle = job?['title'] as String? ?? 'Job';
      final paymentAmount =
          (job?['payout_per_creator'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now().toIso8601String();

      // 1) Update application status
      await SupabaseService.client.from('applications').update({
        'status': 'approved',
        'reviewed_at': now,
        'reviewed_by': admin.id,
      }).eq('id', applicationId);

      // 2) Credit wallet atomically
      if (paymentAmount > 0) {
        await SupabaseService.client.rpc('credit_wallet', params: {
          'p_user_id': userId,
          'p_amount': paymentAmount,
        });
      }

      // 3) In-app notification
      await SupabaseService.client.from('notifications').insert({
        'user_id': userId,
        'title': '🎉 Job Approved!',
        'body':
            'Your submission for "$jobTitle" has been approved. ₹${paymentAmount.toStringAsFixed(0)} has been credited to your wallet.',
        'type': 'job_approved',
        'is_read': false,
        'created_at': now,
      });

      state = const AsyncValue.data(null);
      ref.invalidate(adminJobSubmissionsProvider);
      ref.invalidate(myJobApplicationsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reject a job submission with an optional reason.
  /// Inserts an in-app notification for the user.
  Future<bool> rejectJobSubmission(
    String applicationId, {
    String? rejectionReason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final admin = SupabaseService.currentUser;
      if (admin == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      // Fetch application to get creator_id and campaign_id, then campaign
      // (job) title separately.
      final app = await SupabaseService.client
          .from('applications')
          .select('creator_id, campaign_id')
          .eq('id', applicationId)
          .maybeSingle();

      if (app == null) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final userId = app['creator_id'] as String;
      final jobId = app['campaign_id'] as String;
      final job = await SupabaseService.client
          .from('campaigns')
          .select('title')
          .eq('id', jobId)
          .maybeSingle();
      final jobTitle = job?['title'] as String? ?? 'Job';
      final now = DateTime.now().toIso8601String();

      // 1) Update application status + rejection reason
      await SupabaseService.client.from('applications').update({
        'status': 'rejected',
        'rejection_reason': rejectionReason,
        'reviewed_at': now,
        'reviewed_by': admin.id,
      }).eq('id', applicationId);

      // 2) In-app notification
      final body = rejectionReason != null && rejectionReason.trim().isNotEmpty
          ? 'Your submission for "$jobTitle" was not approved. Reason: $rejectionReason'
          : 'Your submission for "$jobTitle" was not approved.';

      await SupabaseService.client.from('notifications').insert({
        'user_id': userId,
        'title': 'Submission Rejected',
        'body': body,
        'type': 'job_rejected',
        'is_read': false,
        'created_at': now,
      });

      state = const AsyncValue.data(null);
      ref.invalidate(adminJobSubmissionsProvider);
      ref.invalidate(myJobApplicationsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final jobsActionsProvider =
    StateNotifierProvider<JobsActionsNotifier, AsyncValue<void>>((ref) {
  return JobsActionsNotifier(ref);
});
