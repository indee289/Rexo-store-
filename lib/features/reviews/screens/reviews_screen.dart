import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_sheet.dart';
import '../../../core/widgets/premium_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../providers/reviews_provider.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating_widget.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;

  const ReviewsScreen({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    final param = ReviewsParam(
      targetId: widget.targetId,
      targetType: widget.targetType,
    );
    final reviewsAsync = ref.watch(reviewsProvider(param));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Reviews', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.edit, color: Colors.white, size: 20),
        label: Text(
          'Add review',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(reviews);
        },
        loading: () => const ShimmerLoading(),
        error: (error, _) => _buildErrorState(ErrorUtils.sanitize(error)),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> reviews) {
    // Calculate average rating
    double averageRating = 0.0;
    if (reviews.isNotEmpty) {
      final totalRating = reviews.fold<int>(
        0,
        (sum, r) => sum + ((r['rating'] as int?) ?? 0),
      );
      averageRating = totalRating / reviews.length;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Average rating card
        _buildAverageRatingCard(averageRating, reviews.length),
        const SizedBox(height: AppSpacing.xl),
        // Review list
        ...reviews.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ReviewCard(review: review),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildAverageRatingCard(double average, int count) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StarRatingCompact(rating: average, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count ${count == 1 ? 'review' : 'reviews'}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showPremiumSheet<void>(
      context: context,
      title: 'Write a review',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: StarRatingWidget(
                  rating: selectedRating,
                  size: 36,
                  onChanged: (rating) {
                    setModalState(() => selectedRating = rating);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumTextField.multiline(
                controller: commentController,
                hint: 'Share your experience...',
                minLines: 4,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: 'Submit review',
                gradient: true,
                onPressed: selectedRating > 0
                    ? () => _submitReview(
                          context,
                          selectedRating,
                          commentController.text,
                        )
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext sheetContext,
    int rating,
    String comment,
  ) async {
    final success =
        await ref.read(reviewNotifierProvider.notifier).submitReview(
              targetId: widget.targetId,
              targetType: widget.targetType,
              rating: rating,
              comment: comment.trim(),
            );

    if (!mounted) return;

    Navigator.of(sheetContext).pop();

    if (success) {
      ref.invalidate(reviewsProvider(ReviewsParam(
        targetId: widget.targetId,
        targetType: widget.targetType,
      )));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review submitted!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.allSm,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit review'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.allSm,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Iconsax.star_1,
      title: 'No reviews yet',
      subtitle: 'Be the first to leave a review',
    );
  }

  Widget _buildErrorState(String error) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Failed to load reviews',
      subtitle: error,
      ctaLabel: 'Retry',
      ctaIcon: Iconsax.refresh,
      onCta: () {
        ref.invalidate(reviewsProvider(ReviewsParam(
          targetId: widget.targetId,
          targetType: widget.targetType,
        )));
      },
    );
  }
}
