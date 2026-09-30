import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';

/// Result of an account-deletion attempt.
class AccountDeletionResult {
  /// Whether the user's personal data was anonymized/purged server-side.
  final bool anonymized;

  /// Whether the underlying auth user was fully hard-deleted (Edge Function).
  final bool hardDeleted;

  /// Non-null when the attempt failed.
  final String? error;

  const AccountDeletionResult({
    required this.anonymized,
    required this.hardDeleted,
    this.error,
  });

  bool get isSuccess => error == null && anonymized;

  const AccountDeletionResult.failure(String message)
      : anonymized = false,
        hardDeleted = false,
        error = message;
}

/// State for the delete-account flow.
class AccountDeletionState {
  final bool isLoading;
  final AccountDeletionResult? result;

  const AccountDeletionState({this.isLoading = false, this.result});

  AccountDeletionState copyWith({bool? isLoading, AccountDeletionResult? result}) {
    return AccountDeletionState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

/// Orchestrates real account deletion.
///
/// Deletion identity is ALWAYS derived server-side from the authenticated
/// session (auth.uid()) — this client never sends a user id to authorize the
/// deletion. Two server paths are attempted, most-complete first:
///
///  1. Edge Function `delete-account` — anonymizes personal data via the
///     RLS-safe RPC AND hard-deletes the auth user (service role). Preferred.
///  2. Fallback: the RPC `request_account_deletion` directly — anonymizes and
///     locks the account (isBanned) when the Edge Function is not deployed.
///
/// Either path guarantees the user's personal data is removed/anonymized.
class AccountDeletionNotifier extends StateNotifier<AccountDeletionState> {
  AccountDeletionNotifier() : super(const AccountDeletionState());

  Future<AccountDeletionResult> deleteAccount({String? reason}) async {
    state = state.copyWith(isLoading: true);
    final client = SupabaseService.client;

    bool anonymized = false;
    bool hardDeleted = false;

    // 1) Preferred path — Edge Function (anonymize + hard-delete auth user).
    try {
      final res = await client.functions.invoke(
        'delete-account',
        body: {'reason': reason},
      );
      final status = res.status;
      if (status == 200) {
        anonymized = true;
        hardDeleted = true;
      } else if (status == 207) {
        // Data anonymized + account locked, auth-user delete deferred to admin.
        anonymized = true;
      }
    } catch (_) {
      // Edge Function not deployed / offline — fall through to the RPC.
    }

    // 2) Fallback path — RPC directly (anonymize + lock the account).
    if (!anonymized) {
      try {
        await client.rpc(
          'request_account_deletion',
          params: {'p_reason': reason},
        );
        anonymized = true;
      } catch (e) {
        final result = AccountDeletionResult.failure(
          'We could not delete your account right now. Please try again.',
        );
        state = AccountDeletionState(isLoading: false, result: result);
        return result;
      }
    }

    final result = AccountDeletionResult(
      anonymized: anonymized,
      hardDeleted: hardDeleted,
    );
    state = AccountDeletionState(isLoading: false, result: result);
    return result;
  }
}

final accountDeletionProvider =
    StateNotifierProvider<AccountDeletionNotifier, AccountDeletionState>(
  (ref) => AccountDeletionNotifier(),
);
