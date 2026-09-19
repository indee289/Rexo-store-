import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

// ─── Filter / Search State ────────────────────────────────────────────────────

/// Active category filter on the Available Jobs tab ('All' = no filter).
final jobCategoryFilterProvider = StateProvider<String>((ref) => 'All');

/// Search term on the Available Jobs tab.
final jobSearchProvider = StateProvider<String>((ref) => '');

/// Status filter on My Jobs tab.
final myJobsStatusFilterProvider = StateProvider<String>((ref) => 'all');

// ─── Available Jobs ───────────────────────────────────────────────────────────

/// All active jobs, filtered by category + search term.
final availableJobsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final category = ref.watch(jobCategoryFilterProvider);
  final search = ref.watch(jobSearchProvider);

  var query = SupabaseService.client
      .from('jobs')
      .select('*, users!created_by(id, name, avatar_url)')
      .eq('status', 'active');

  if (category != 'All') {
    query = query.eq('category', category);
  }

  if (search.isNotEmpty) {
    query = query.ilike('title', '%$search%');
  }

  final response = await query.order('created_at', ascending: false).limit(100);
  return List<Map<String, dynamic>>.from(response);
});

/// Distinct categories derived from existing active jobs (dynamic, no hardcode).
final jobCategoriesProvider = FutureProvider<List<String>>((ref) async {
  // Watch availableJobs so we only derive from what's actually showing
  final jobs = await SupabaseService.client
      .from('jobs')
      .select('category')
      .eq('status', 'active');

  final cats = <String>{};
  for (final row in List<Map<String, dynamic>>.from(jobs)) {
    final cat = row['category'] as String?;
    if (cat != null && cat.trim().isNotEmpty) cats.add(cat.trim());
  }
  final sorted = cats.toList()..sort();
  return ['All', ...sorted];
});

/// Slot counts for a single job: returns { filled: int, max: int? }.
final jobSlotCountProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
        (ref, jobId) async {
  final response = await SupabaseService.client
      .from('job_applications')
      .select('id')
      .eq('job_id', jobId)
      .inFilter('status', ['applied', 'submitted', 'approved']);

  final filled = (response as List).length;
  return {'filled': filled};
});

// ─── Job Detail ───────────────────────────────────────────────────────────────

/// Single job detail (with creator info).
final jobDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, jobId) async {
  final response = await SupabaseService.client
      .from('jobs')
      .select('*, users!created_by(id, name, avatar_url)')
      .eq('id', jobId)
      .maybeSingle();
  return response;
});

/// Whether the current user has already applied to a specific job.
final hasAppliedToJobProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, jobId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client
      .from('job_applications')
      .select('id')
      .eq('job_id', jobId)
      .eq('user_id', user.id)
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
      .from('job_applications')
      .select(
          '*, jobs(id, title, description, category, payment_amount, max_slots, deadline, cover_image_url, status)')
      .eq('user_id', user.id);

  if (statusFilter != 'all') {
    query = query.eq('status', statusFilter);
  }

  final response = await query.order('applied_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// ─── Admin Providers ──────────────────────────────────────────────────────────

/// All jobs for the admin manage list (all statuses).
final adminJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('jobs')
      .select('*, users!created_by(id, name, avatar_url)')
      .order('created_at', ascending: false)
      .limit(200);
  return List<Map<String, dynamic>>.from(response);
});

/// Applicant count per job (used in admin list).
final adminJobApplicantCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, jobId) async {
  final response = await SupabaseService.client
      .from('job_applications')
      .select('id')
      .eq('job_id', jobId);
  return (response as List).length;
});

/// All submitted (pending review) job applications for admin review.
/// Joins job title and user profile.
final adminJobSubmissionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client
      .from('job_applications')
      .select(
          '*, jobs(id, title, payment_amount), users:user_id(id, name, handle, avatar_url)')
      .eq('status', 'submitted')
      .order('submitted_at', ascending: false)
      .limit(200);
  return List<Map<String, dynamic>>.from(response);
});

// ─── Jobs Actions Notifier ────────────────────────────────────────────────────

class JobsActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  JobsActionsNotifier(this.ref) : super(const AsyncValue.data(null));

  // ── User Actions ──────────────────────────────────────────────────────────

  /// Apply to a job. Enforced server-side by the slot-check trigger.
  Future<bool> applyToJob(String jobId) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('job_applications').insert({
        'job_id': jobId,
        'user_id': user.id,
        'status': 'applied',
        'applied_at': DateTime.now().toIso8601String(),
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
      await SupabaseService.client.from('job_applications').update({
        'status': 'submitted',
        'submission_type': submissionType,
        'submission_url': submissionUrl,
        'submission_note': submissionNote,
        'submitted_at': DateTime.now().toIso8601String(),
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
  Future<bool> createJob(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return false;
      }

      await SupabaseService.client.from('jobs').insert({
        ...data,
        'created_by': user.id,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
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
      await SupabaseService.client.from('jobs').update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);

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

  /// Hard-delete a job (cascades to job_applications via ON DELETE CASCADE).
  Future<bool> deleteJob(String jobId) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.from('jobs').delete().eq('id', jobId);

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

      // Fetch application to get user_id and payment_amount
      final app = await SupabaseService.client
          .from('job_applications')
          .select('user_id, job_id, jobs(title, payment_amount)')
          .eq('id', applicationId)
          .maybeSingle();

      if (app == null) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final userId = app['user_id'] as String;
      final job = app['jobs'] as Map<String, dynamic>? ?? {};
      final jobTitle = job['title'] as String? ?? 'Job';
      final paymentAmount =
          (job['payment_amount'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now().toIso8601String();

      // 1) Update application status
      await SupabaseService.client.from('job_applications').update({
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

      // Fetch application to get user_id and job title
      final app = await SupabaseService.client
          .from('job_applications')
          .select('user_id, job_id, jobs(title)')
          .eq('id', applicationId)
          .maybeSingle();

      if (app == null) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final userId = app['user_id'] as String;
      final job = app['jobs'] as Map<String, dynamic>? ?? {};
      final jobTitle = job['title'] as String? ?? 'Job';
      final now = DateTime.now().toIso8601String();

      // 1) Update application status + rejection reason
      await SupabaseService.client.from('job_applications').update({
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
