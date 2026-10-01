import 'package:flutter/material.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';

/// Computes how complete a user's profile is from the live `users` row.
class ProfileCompleteness {
  /// The profile fields that count toward completeness, with a friendly label.
  static const Map<String, String> _fields = {
    'name': 'name',
    'username': 'username',
    'profileImage': 'profile photo',
    'bio': 'bio',
    'phone': 'phone',
    'category': 'category',
    'instagramLink': 'Instagram link',
  };

  /// Returns the completion percent (0–100).
  static int percent(Map<String, dynamic>? profile) {
    if (profile == null) return 0;
    final filled = _fields.keys.where((k) => _isFilled(profile[k])).length;
    return ((filled / _fields.length) * 100).round();
  }

  /// Friendly labels for the still-missing fields (max [limit]).
  static List<String> missing(Map<String, dynamic>? profile, {int limit = 3}) {
    if (profile == null) return _fields.values.take(limit).toList();
    final out = <String>[];
    _fields.forEach((key, label) {
      if (!_isFilled(profile[key])) out.add(label);
    });
    return out.take(limit).toList();
  }

  static bool _isFilled(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is bool) return v;
    return true;
  }
}

/// A card nudging the user to finish their profile. Renders nothing when the
/// profile is already 100% complete.
class ProfileCompletenessCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onComplete;

  const ProfileCompletenessCard({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ProfileCompleteness.percent(profile);
    if (pct >= 100) return const SizedBox.shrink();

    final missing = ProfileCompleteness.missing(profile);
    final missingText =
        missing.isEmpty ? 'Add more details' : 'Add ${missing.join(', ')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: onComplete,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.user_edit, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete your profile',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: AppTextStyles.subheadline.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                missingText,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
