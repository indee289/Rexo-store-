import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reviews',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.edit, color: Colors.white, size: 20),
        label: Text(
          'Add Review',
          style: GoogleFonts.poppins(
            fontSize: 13,
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
      padding: const EdgeInsets.all(16),
      children: [
        // Average rating card
        _buildAverageRatingCard(averageRating, reviews.length),
        const SizedBox(height: 20),
        // Review list
        ...reviews.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReviewCard(review: review),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildAverageRatingCard(double average, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          StarRatingCompact(rating: average, size: 24),
          const SizedBox(height: 8),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Write a Review', style: AppTextStyles.h5),
                  const SizedBox(height: 16),
                  Center(
                    child: StarRatingWidget(
                      rating: selectedRating,
                      size: 36,
                      onChanged: (rating) {
                        setModalState(() => selectedRating = rating);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      hintStyle: AppTextStyles.bodySmall,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedRating > 0
                          ? () => _submitReview(
                                context,
                                selectedRating,
                                commentController.text,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Submit Review', style: AppTextStyles.button),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            borderRadius: BorderRadius.circular(8),
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.star_1,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to leave a review',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text('Failed to load reviews', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(reviewsProvider(ReviewsParam(
                  targetId: widget.targetId,
                  targetType: widget.targetType,
                )));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
