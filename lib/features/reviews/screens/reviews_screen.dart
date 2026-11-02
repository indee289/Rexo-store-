import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/error_utils.dart';
import '../../../core/widgets/glass/glass.dart';
import '../providers/reviews_provider.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating_widget.dart';

/// Reviews — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a `ListView` whose first child was a
/// `PremiumCard` showing a bare average number, with a
/// `FloatingActionButton.extended` overlapping the list.
///
/// New layout: collapsing large title carrying the review count; the average
/// promoted into a summary card that pairs the number with its star row and
/// total; and the add action as a pill pinned above the safe area rather than a
/// floating button that covers the last review.
///
/// `reviewsProvider`, `reviewNotifierProvider.submitReview` and the
/// `ReviewsParam` keys are unchanged.
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
  ReviewsParam get _param => ReviewsParam(targetId: widget.targetId);

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(reviewsProvider(_param));

    return GlassScaffold(
      padBodyForAppBar: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              GlassLargeTitleHeader(
                title: 'Reviews',
                showBack: true,
                subtitle: reviewsAsync.maybeWhen(
                  data: (r) => r.isEmpty
                      ? null
                      : '${r.length} ${r.length == 1 ? 'review' : 'reviews'}',
                  orElse: () => null,
                ),
              ),
              reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: GlassEmptyState(
                        icon: AppIcons.star_1,
                        title: 'No reviews yet',
                        message: 'Be the first to leave a review.',
                        actionLabel: 'Write a review',
                        onAction: () => _showAddReviewSheet(context),
                      ),
                    );
                  }
                  return _reviewsSliver(reviews);
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassLoader(),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: GlassErrorState(
                    title: 'Failed to load reviews',
                    message: ErrorUtils.sanitize(error),
                    onRetry: () => ref.invalidate(reviewsProvider(_param)),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: GlassButton(
              label: 'Write a review',
              icon: AppIcons.edit,
              onPressed: () => _showAddReviewSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewsSliver(List<Map<String, dynamic>> reviews) {
    final total = reviews.fold<int>(
      0,
      (sum, r) => sum + ((r['rating'] as int?) ?? 0),
    );
    final average = reviews.isEmpty ? 0.0 : total / reviews.length;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        96,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _AverageCard(average: average, count: reviews.length),
          AppSpacing.gapLg,
          for (final review in reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RepaintBoundary(child: ReviewCard(review: review)),
            ),
        ]),
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showGlassSheet<void>(
      context: context,
      title: 'Write a review',
      subtitle: 'Your rating helps others decide',
      child: StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: StarRatingWidget(
                  rating: selectedRating,
                  size: 38,
                  onChanged: (rating) =>
                      setModalState(() => selectedRating = rating),
                ),
              ),
              AppSpacing.gapLg,
              GlassTextField.multiline(
                controller: commentController,
                hint: 'Share your experience...',
                minLines: 4,
                maxLines: 6,
              ),
              AppSpacing.gapXl,
              GlassButton(
                label: 'Submit review',
                size: GlassButtonSize.medium,
                onPressed: selectedRating > 0
                    ? () => _submitReview(
                          sheetContext,
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
              rating: rating,
              comment: comment.trim(),
            );

    if (!mounted) return;

    Navigator.of(sheetContext).pop();

    if (success) {
      ref.invalidate(reviewsProvider(_param));
      showGlassSnackBar(
        context,
        message: 'Review submitted!',
        tone: GlassToastTone.success,
      );
    } else {
      showGlassSnackBar(
        context,
        message: 'Failed to submit review',
        tone: GlassToastTone.error,
      );
    }
  }
}

/// Average rating summary.
class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.allXl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: AppTextStyles.largeTitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 44,
              letterSpacing: -1,
            ),
          ),
          AppSpacing.gapSm,
          StarRatingCompact(rating: average, size: 22),
          AppSpacing.gapSm,
          Text(
            '$count ${count == 1 ? 'review' : 'reviews'}',
            style: AppTextStyles.footnote
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
