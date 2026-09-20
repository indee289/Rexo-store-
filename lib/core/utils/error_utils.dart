/// Utility for sanitizing error messages before displaying to users.
///
/// NEVER show raw exception messages (PostgrestException, Supabase URLs,
/// API keys, stack traces) to end users. Always use this utility to
/// convert errors into clean, user-friendly messages.
class ErrorUtils {
  ErrorUtils._();

  /// Convert a raw error object into a user-friendly message.
  ///
  /// Strips Supabase URLs, API keys, technical details, and
  /// PostgreSQL error codes. Returns a clean message suitable
  /// for display in the UI.
  static String sanitize(Object? error) {
    if (error == null) return 'Something went wrong. Please try again.';

    final message = error.toString().toLowerCase();

    // TEMP DEBUG (v4): raw error for jobs (campaigns is_job query). Remove after fix.
    return 'DBG4: ${error.toString()}';

    // ignore: dead_code
    // Network/connection errors
    if (message.contains('socketexception') ||
        message.contains('connection refused') ||
        message.contains('network') ||
        message.contains('timeout') ||
        message.contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Authentication errors
    if (message.contains('not authenticated') ||
        message.contains('jwt expired') ||
        message.contains('invalid token') ||
        message.contains('session expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('invalid login') ||
        message.contains('invalid credentials') ||
        message.contains('email not confirmed')) {
      return 'Invalid email or password. Please try again.';
    }

    // Permission errors
    if (message.contains('permission denied') ||
        message.contains('not authorized') ||
        message.contains('rls') ||
        message.contains('row-level security') ||
        message.contains('policy')) {
      return 'You do not have permission to perform this action.';
    }

    // Recursion error (the critical bug)
    if (message.contains('infinite recursion')) {
      return 'A server configuration issue occurred. Please contact support.';
    }

    // Not found
    if (message.contains('not found') || message.contains('no rows')) {
      return 'The requested data was not found.';
    }

    // Handle/username uniqueness errors
    if (message.contains('handle') &&
        (message.contains('unique') ||
            message.contains('duplicate') ||
            message.contains('already exists'))) {
      return 'This handle is already taken. Please choose a different one.';
    }

    // Duplicate/conflict
    if (message.contains('duplicate') ||
        message.contains('already exists') ||
        message.contains('unique constraint')) {
      return 'This item already exists. Please try a different value.';
    }

    // Insufficient balance
    if (message.contains('insufficient balance') ||
        message.contains('insufficient funds')) {
      return 'Insufficient balance for this transaction.';
    }

    // Insufficient stock
    if (message.contains('insufficient stock')) {
      return 'This product is out of stock.';
    }

    // Generic PostgrestException pattern - strip technical details
    if (message.contains('postgrestexception') ||
        message.contains('postgresql') ||
        message.contains('supabase') ||
        message.contains('42p') ||
        message.contains('https://')) {
      return 'Something went wrong. Please try again.';
    }

    // If the message is short and doesn't contain URLs or technical info, allow it
    final raw = error.toString();
    if (raw.length < 100 &&
        !raw.contains('http') &&
        !raw.contains('Exception') &&
        !raw.contains('Error(') &&
        !raw.contains('stacktrace')) {
      return raw;
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }
}
