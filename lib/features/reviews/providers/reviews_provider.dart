import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/supabase_service.dart';

/// Parameter class for fetching reviews
class ReviewsParam {
  final String targetId;
  final String targetType;

  const ReviewsParam({required this.targetId, required this.targetType});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewsParam &&
          other.targetId == targetId &&
          other.targetType == targetType;

  @override
  int get hashCode => targetId.hashCode ^ targetType.hashCode;
}

/// Provider for reviews of a specific target
final reviewsProvider = FutureProvider.family<List<Map<String, dynamic>>,
    ReviewsParam>((ref, param) async {
  final response = await SupabaseService.client
      .from('reviews')
      .select()
      .eq('target_id', param.targetId)
      .eq('target_type', param.targetType)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

/// State for submitting a review
class ReviewFormState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const ReviewFormState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  ReviewFormState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
  }) {
    return ReviewFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// StateNotifier for submitting a review
class ReviewNotifier extends StateNotifier<ReviewFormState> {
  ReviewNotifier() : super(const ReviewFormState());

  Future<bool> submitReview({
    required String targetId,
    required String targetType,
    required int rating,
    required String comment,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'User not authenticated',
        );
        return false;
      }

      const uuid = Uuid();
      await SupabaseService.client.from('reviews').insert({
        'id': uuid.v4(),
        'user_id': user.id,
        'target_id': targetId,
        'target_type': targetType,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });

      state = state.copyWith(isSubmitting: false, success: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const ReviewFormState();
  }
}

/// Provider for the review notifier
final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, ReviewFormState>((ref) {
  return ReviewNotifier();
});
