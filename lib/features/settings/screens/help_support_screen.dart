import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';
import '../../../core/widgets/premium_card.dart';

/// Help & Support screen with real contact options: email support, a short
/// FAQ, and a shortcut to the in-app inbox to message the team.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = AppConstants.adminEmail;

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('Rexo Support Request')}',
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open email app. Write to $_supportEmail'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PremiumAppBar(
        title: 'Help & Support',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'We\'re here to help',
            style: AppTextStyles.h5.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reach out to the Rexo team and we\'ll get back to you as soon as we can.',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl - 4),

          // Contact options
          _ContactCard(
            icon: Iconsax.sms,
            title: 'Email Support',
            subtitle: _supportEmail,
            onTap: () => _emailSupport(context),
          ),
          const SizedBox(height: AppSpacing.md),
          _ContactCard(
            icon: Iconsax.message,
            title: 'Message us',
            subtitle: 'Chat with us from your inbox',
            onTap: () => context.push('/messages'),
          ),

          const SizedBox(height: AppSpacing.xxl - 4),
          Text(
            'Frequently Asked Questions',
            style: AppTextStyles.h6.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _FaqTile(
            question: 'How do I apply to a campaign?',
            answer:
                'Open a campaign from the Campaigns tab and tap "Apply". Fill in '
                'your details and pitch, then submit. The brand will review your '
                'application and respond.',
          ),
          const _FaqTile(
            question: 'When do I get paid for a campaign?',
            answer:
                'Payouts are released to your wallet after the brand approves '
                'your submission. You can withdraw available balance from the '
                'Wallet screen.',
          ),
          const _FaqTile(
            question: 'How do I verify my account (KYC)?',
            answer:
                'Go to Settings → KYC Verification and upload the requested '
                'documents. Our team reviews submissions and updates your status.',
          ),
          const _FaqTile(
            question: 'How do I contact a brand or creator?',
            answer:
                'Use the Inbox tab. Tap the new-chat button to search for a user '
                'by name or handle and start a conversation.',
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.arrow_right_3,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        title: Text(
          question,
          style: AppTextStyles.labelLarge.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: theme.colorScheme.onSurface.withOpacity(0.5),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
