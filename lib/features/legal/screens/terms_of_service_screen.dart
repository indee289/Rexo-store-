import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/premium_app_bar.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumAppBar(title: 'Terms of Service', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 1, 2024',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              context,
              'Acceptance of Terms',
              'By accessing and using the Rexo Marketplace platform ("Platform"), you accept and agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must not use the Platform. These Terms constitute a legally binding agreement between you and Rexo Agency ("Company," "we," "our," or "us").',
            ),
            _buildSection(
              context,
              'Account Registration',
              '1. You must be at least 18 years old to create an account on the Platform.\n\n2. You agree to provide accurate, current, and complete information during registration and to update such information as necessary.\n\n3. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n4. You must complete KYC (Know Your Customer) verification before accessing certain features including campaign payments and withdrawals.\n\n5. We reserve the right to suspend or terminate accounts that violate these Terms, provide false information, or engage in fraudulent activity.',
            ),
            _buildSection(
              context,
              'Platform Usage',
              'The Rexo Marketplace connects brands with content creators and influencers for marketing campaigns. By using the Platform:\n\n1. Creators agree to:\n- Provide authentic follower and engagement data\n- Complete campaign deliverables within agreed timelines\n- Create original content that complies with advertising standards\n- Disclose sponsored content as per FTC/ASCI guidelines\n- Not use bots, fake engagement, or fraudulent methods\n\n2. Brands agree to:\n- Provide clear campaign briefs and expectations\n- Make timely payments for completed work\n- Not request content that violates laws or platform guidelines\n- Respect intellectual property rights of creators\n\n3. All users agree to:\n- Not harass, abuse, or threaten other users\n- Not post misleading, false, or defamatory content\n- Not attempt to circumvent Platform fees by transacting outside the Platform\n- Not use the Platform for any unlawful purpose',
            ),
            _buildSection(
              context,
              'Payments and Transactions',
              '1. All campaign payments are processed through the Platform wallet system.\n\n2. Brands must deposit funds before a campaign is marked active. These funds are held in escrow until campaign completion.\n\n3. Creator payments are released upon campaign approval by the brand or after the dispute resolution period (7 days).\n\n4. Platform fees: A service fee is deducted from each transaction. Current fee structure is displayed on the Platform.\n\n5. Withdrawals are processed within 3-5 business days to the verified bank account or UPI ID on file.\n\n6. All transactions are subject to applicable taxes. Users are responsible for their own tax obligations.\n\n7. Chargebacks or payment reversals may result in account suspension pending investigation.',
            ),
            _buildSection(
              context,
              'Disputes and Resolution',
              '1. If a brand is not satisfied with campaign deliverables, they may raise a dispute within 7 days of submission.\n\n2. Disputes will be reviewed by our moderation team within 5 business days.\n\n3. During dispute resolution, payment is held in escrow and not released to either party.\n\n4. Our dispute resolution decision is final. In cases of clear violation, partial or full refunds may be issued.\n\n5. Repeated disputes may affect your platform reputation score and account standing.',
            ),
            _buildSection(
              context,
              'Intellectual Property',
              '1. Creators retain ownership of their original content unless otherwise agreed in a specific campaign brief.\n\n2. By posting content on the Platform, you grant us a non-exclusive, worldwide license to display, reproduce, and distribute such content for Platform operation and promotion.\n\n3. Brands receive a license to use creator content as specified in the campaign agreement.\n\n4. You must not infringe on third-party intellectual property rights. Content that violates copyright will be removed.\n\n5. The Rexo name, logo, and Platform design are our trademarks and may not be used without permission.',
            ),
            _buildSection(
              context,
              'Content Moderation',
              '1. We employ automated AI moderation and manual review to ensure content compliance.\n\n2. Content that violates our Community Guidelines will be removed without notice.\n\n3. Prohibited content includes but is not limited to:\n- Hate speech or discrimination\n- Sexually explicit material\n- Violence or harmful activities\n- Spam or misleading information\n- Illegal products or services\n\n4. Repeated violations will result in warnings, suspension, or permanent account termination.',
            ),
            _buildSection(
              context,
              'Account Suspension and Termination',
              '1. We may suspend or terminate your account for:\n- Violation of these Terms\n- Fraudulent activity or fake engagement\n- Failure to complete KYC verification when required\n- Inactivity for more than 12 months\n- At our sole discretion for safety or legal reasons\n\n2. Upon termination:\n- Pending payments will be processed according to their status\n- You lose access to all Platform features\n- Your data will be retained per our Privacy Policy\n\n3. You may appeal a suspension through the in-app appeal process within 30 days.',
            ),
            _buildSection(
              context,
              'Limitation of Liability',
              '1. The Platform is provided "as is" without warranties of any kind.\n\n2. We are not liable for:\n- Loss of profits or data\n- Campaign outcomes or performance\n- Actions of other users\n- Service interruptions or technical issues\n- Third-party content or links\n\n3. Our total liability is limited to the fees paid to us in the 12 months preceding the claim.\n\n4. We are not responsible for disputes between brands and creators beyond our stated resolution process.',
            ),
            _buildSection(
              context,
              'Governing Law',
              'These Terms are governed by and construed in accordance with the laws of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts in Bangalore, India.',
            ),
            _buildSection(
              context,
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. Material changes will be communicated via email or in-app notification at least 14 days before they take effect. Continued use of the Platform after changes constitutes acceptance of the modified Terms.',
            ),
            _buildSection(
              context,
              'Contact Information',
              'For questions about these Terms of Service, please contact us:\n\nEmail: legal@rexoagency.in\nAddress: Rexo Agency, India\nSupport: Available through the Help & Support section in the app.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h6.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
