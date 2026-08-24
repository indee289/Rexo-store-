import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Lifecycle status of a campaign application.
///
/// Used by the applied-campaigns Campaigns tab to render a per-card status
/// chip. [unknown] is a defensive fallback for any status string that does not
/// match a known lifecycle value (or a null/missing status).
enum ApplicationStatus { pending, approved, rejected, unknown }

extension ApplicationStatusX on ApplicationStatus {
  /// Human-readable label shown on the status chip.
  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.unknown:
        return 'Unknown';
    }
  }

  /// Status color, sourced from the theme tokens:
  /// pending → warning, approved → success, rejected → error.
  Color color(BuildContext context) {
    switch (this) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.unknown:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
  }

  /// Maps a raw status string (e.g. from the `applications.status` column) to
  /// an [ApplicationStatus]. Case-insensitive; null/unrecognized values map to
  /// [ApplicationStatus.unknown].
  static ApplicationStatus fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.unknown;
    }
  }
}
