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

  final response = await SupabaseService.client.rpc('get_active_jobs', params: {
    'p_category': category == 'All' ? null : category,
    'p_search': search.isEmpty ? null : search,
  });
  return List<Map<String, dynamic>>.from(response as List);
});

/// Distinct categories derived from existing active jobs (dynamic, no hardcode).
final jobCategoriesProvider = FutureProvider<List<String>>((ref) async {
  // Derive from all active jobs (no filters applied)
  final response = await SupabaseService.client.rpc('get_active_jobs', params: {
    'p_category': null,
    'p_search': null,
  });

  final cats = <String>{};
  for (final row in List<Map<String, dynamic>>.from(response as List)) {
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
      .rpc('get_job_slot_count', params: {'p_job_id': jobId});

  final filled = (response as int?) ?? (response as num).toInt();
  return {'filled': filled};
});

// ─── Job Detail ───────────────────────────────────────────────────────────────

/// Single job detail (with creator info).
final jobDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
        (ref, jobId) async {
  final response = await SupabaseService.client
      .rpc('get_job_by_id', params: {'p_job_id': jobId});
  final list = List<Map<String, dynamic>>.from(response as List);
  return list.isEmpty ? null : list.first;
});

/// Whether the current user has already applied to a specific job.
final hasAppliedToJobProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, jobId) async {
  final user = SupabaseService.currentUser;
  if (user == null) return false;

  final response = await SupabaseService.client.rpc('has_applied_to_job',
      params: {'p_job_id': jobId, 'p_user_id': user.id});

  return response == true;
});

// ─── My Jobs ─────────────────────────────────────────────────────────────────

/// The current user's job applications, joined with the job details.
/// Optionally filtered by status (pass 'all' for no filter).
final myJobApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return [];

  final statusFilter = ref.watch(myJobsStatusFilterProvider);

  final response = await SupabaseService.client
      .rpc('get_job_applications', params: {'p_user_id': user.id});
  var rows = List<Map<String, dynamic>>.from(response as List);

  // Apply status filter client-side (RPC already orders by applied_at DESC).
  if (statusFilter != 'all') {
    rows = rows.where((r) => r['status'] == statusFilter).toList();
  }

  // Fetch each job separately (avoids embedded-join RLS/PGRST issues)
  final enriched = <Map<String, dynamic>>[];
  for (final row in rows) {
    final jobId = row['job_id'] as String?;
    Map<String, dynamic>? jobRow;
    if (jobId != null) {
      try {
        final jobResponse = await SupabaseService.client
            .rpc('get_job_by_id', params: {'p_job_id': jobId});
        final jobList = List<Map<String, dynamic>>.from(jobResponse as List);
        jobRow = jobList.isEmpty ? null : jobList.first;
      } catch (_) {}
    }
    enriched.add({...row, 'jobs': jobRow ?? {}});
  }
  return enriched;
});

// ─── Admin Providers ──────────────────────────────────────────────────────────

/// All jobs for the admin manage list (all statuses).
/// No user join — the foreign-key join on created_by can fail RLS on some
/// Supabase configs; the admin list only needs the core job fields.
final adminJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseService.client.rpc('get_jobs');
  return List<Map<String, dynamic>>.from(response as List);
});

/// Applicant count per job (used in admin list).
final adminJobApplicantCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, jobId) async {
  final response = await SupabaseService.client
      .rpc('get_job_applicant_count', params: {'p_job_id': jobId});
  return (response as int?) ?? (response as num).toInt();
});

/// All submitted (pending review) job applications for admin review.
/// Simple join — no nested user join to avoid RLS issues.
final adminJobSubmissionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response =
      await SupabaseService.client.rpc('get_submitted_applications');
  final rows = List<Map<String, dynamic>>.from(response as List);

  // Fetch job + user details separately to avoid embedded-join failures
  final enriched = <Map<String, dynamic>>[];
  for (final row in rows) {
    final userId = row['user_id'] as String?;
    final jobId = row['job_id'] as String?;
    Map<String, dynamic>? userRow;
    Map<String, dynamic>? jobRow;
    if (userId != null) {
      try {
        userRow = await SupabaseService.client
            .from('users')
            .select('id, name, handle, avatar_url')
            .eq('id', userId)
            .maybeSingle();
      } catch (_) {}
    }
    if (jobId != null) {
      try {
        final jobResponse = await SupabaseService.client
            .rpc('get_job_by_id', params: {'p_job_id': jobId});
        final jobList = List<Map<String, dynamic>>.from(jobResponse as List);
        jobRow = jobList.isEmpty ? null : jobList.first;
      } catch (_) {}
    }
    enriched.add({...row, 'users': userRow ?? {}, 'jobs': jobRow ?? {}});
  }
  return enriched;
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

      await SupabaseService.client
          .rpc('apply_to_job', params: {'p_job_id': jobId});

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
      await SupabaseService.client.rpc('submit_job_task', params: {
        'p_application_id': applicationId,
        'p_submission_type': submissionType,
        'p_submission_url': submissionUrl,
        'p_submission_note': submissionNote,
      });

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

      await SupabaseService.client.rpc('create_job', params: {'p_data': data});

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
      await SupabaseService.client
          .rpc('update_job', params: {'p_job_id': jobId, 'p_data': data});

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
      await SupabaseService.client
          .rpc('delete_job', params: {'p_job_id': jobId});

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

      // Fetch application core ids, then job separately (no embedded join)
      final appResponse = await SupabaseService.client
          .rpc('get_application_core', params: {'p_application_id': applicationId});
      final appRows = List<Map<String, dynamic>>.from(appResponse as List);

      if (appRows.isEmpty) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final app = appRows.first;
      final userId = app['user_id'] as String;
      final jobId = app['job_id'] as String;
      final jobResponse = await SupabaseService.client
          .rpc('get_job_by_id', params: {'p_job_id': jobId});
      final jobList = List<Map<String, dynamic>>.from(jobResponse as List);
      final job = jobList.isEmpty ? <String, dynamic>{} : jobList.first;
      final jobTitle = job['title'] as String? ?? 'Job';
      final paymentAmount =
          (job['payment_amount'] as num?)?.toDouble() ?? 0.0;

      final now = DateTime.now().toIso8601String();

      // 1) Update application status
      await SupabaseService.client.rpc('update_application_status', params: {
        'p_application_id': applicationId,
        'p_status': 'approved',
      });

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

      // Fetch application core ids, then job title separately (no embedded join)
      final appResponse = await SupabaseService.client
          .rpc('get_application_core', params: {'p_application_id': applicationId});
      final appRows = List<Map<String, dynamic>>.from(appResponse as List);

      if (appRows.isEmpty) {
        state = AsyncValue.error('Application not found', StackTrace.current);
        return false;
      }

      final app = appRows.first;
      final userId = app['user_id'] as String;
      final jobId = app['job_id'] as String;
      final jobResponse = await SupabaseService.client
          .rpc('get_job_by_id', params: {'p_job_id': jobId});
      final jobList = List<Map<String, dynamic>>.from(jobResponse as List);
      final job = jobList.isEmpty ? <String, dynamic>{} : jobList.first;
      final jobTitle = job['title'] as String? ?? 'Job';
      final now = DateTime.now().toIso8601String();

      // 1) Update application status + rejection reason
      await SupabaseService.client.rpc('update_application_status', params: {
        'p_application_id': applicationId,
        'p_status': 'rejected',
        'p_rejection_reason': rejectionReason,
      });

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
