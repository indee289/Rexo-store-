import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rexo_marketplace/core/icons/app_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/admin_notify.dart';
import '../../../core/widgets/glass/glass.dart';
import '../../../services/supabase_service.dart';

/// Help & Support — rebuilt layout.
///
/// Old layout: `PremiumAppBar` over a `ListView` of two `PremiumCard` contact
/// tiles followed by Material `ExpansionTile`s for the FAQ, each with its own
/// `Theme` override to hide the divider it would otherwise draw.
///
/// New layout: collapsing large title; contact options as a grouped section so
/// the two routes to support read as one choice; and the FAQ as expandable
/// rows inside their own section, without the per-tile Theme hack.
///
/// Email launch, the support-admin lookup, the `/messages/{adminId}` route and
/// all copy are unchanged.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = AppConstants.supportEmail;

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Campster Support Request')}',
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      showGlassSnackBar(
        context,
        message: 'Could not open email app. Write to $_supportEmail',
        tone: GlassToastTone.error,
      );
    }
  }

  /// Opens a direct chat with the Campster admin so the user can talk to the
  /// team straight from Help (previously this only opened the user's own
  /// inbox with nobody selected).
  Future<void> _messageAdmin(BuildContext context) async {
    final router = GoRouter.of(context);

    if (SupabaseService.currentUser == null) {
      showGlassSnackBar(
        context,
        message: 'Please sign in to message support.',
        tone: GlassToastTone.warning,
      );
      return;
    }

    final adminId = await AdminNotify.supportAdminId();
    if (adminId == null) {
      if (!context.mounted) return;
      showGlassSnackBar(
        context,
        message: 'Support chat is unavailable right now. '
            'Email us at $_supportEmail',
        tone: GlassToastTone.error,
      );
      return;
    }
    router.push('/messages/$adminId');
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      padBodyForAppBar: false,
      body: CustomScrollView(
        slivers: [
          GlassLargeTitleHeader(
            title: 'Help & support',
            subtitle: "We're here to help",
            showBack: true,
            onBack: () => context.pop(),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Text(
                "Reach out to the Campster team and we'll get back to you as "
                'soon as we can.',
                style: AppTextStyles.subheadline.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Contact us',
              children: [
                GlassRow(
                  icon: AppIcons.sms,
                  title: 'Email support',
                  subtitle: _supportEmail,
                  onTap: () => _emailSupport(context),
                ),
                GlassRow(
                  icon: AppIcons.message,
                  title: 'Message us',
                  subtitle: 'Chat directly with the Campster admin',
                  onTap: () => _messageAdmin(context),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: GlassSection(
              title: 'Frequently asked questions',
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
              ),
              children: const [
                _FaqRow(
                  question: 'How do I apply to a campaign?',
                  answer:
                      'Open a campaign from the Campaigns tab and tap "Apply". '
                      'Fill in your details and pitch, then submit. The brand '
                      'will review your application and respond.',
                ),
                _FaqRow(
                  question: 'When do I get paid for a campaign?',
                  answer:
                      'Payouts are released to your wallet after the brand '
                      'approves your submission. You can withdraw available '
                      'balance from the Wallet screen.',
                ),
                _FaqRow(
                  question: 'How do I contact a brand or creator?',
                  answer:
                      'Use the Inbox tab. Tap the new-chat button to search '
                      'for a user by name or handle and start a conversation.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable FAQ row.
///
/// Hand-rolled rather than an `ExpansionTile`: the Material tile draws its own
/// divider and arrow chrome that had to be suppressed with a `Theme` override
/// at every call-site.
class _FaqRow extends StatefulWidget {
  const _FaqRow({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _open = !_open),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    AppIcons.arrow_down_1,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        right: AppSpacing.lg,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: AppRadius.allMd,
                        ),
                        child: Text(
                          widget.answer,
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
