import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/legal_document.dart';

/// Terms of Service — rebuilt layout.
///
/// Content is unchanged. The page structure now comes from [LegalDocument],
/// which is shared with the other legal screen: a collapsing large title, an
/// "updated" chip, and one numbered card per clause instead of an
/// undifferentiated run of heading-and-paragraph pairs.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const List<LegalSection> _sections = [
    LegalSection(
      'Acceptance of Terms',
      'By accessing and using the Campster platform ("Platform"), you accept and agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must not use the Platform. These Terms constitute a legally binding agreement between you and Campster ("Company," "we," "our," or "us").',
    ),
    LegalSection(
      'Account Registration',
      '1. You must be at least 18 years old to create an account on the Platform.\n\n2. You agree to provide accurate, current, and complete information during registration and to update such information as necessary.\n\n3. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n4. We reserve the right to suspend or terminate accounts that violate these Terms, provide false information, or engage in fraudulent activity.',
    ),
    LegalSection(
      'Platform Usage',
      'Campster connects brands with content creators and influencers for marketing campaigns. By using the Platform:\n\n1. Creators agree to:\n- Provide authentic follower and engagement data\n- Complete campaign deliverables within agreed timelines\n- Create original content that complies with advertising standards\n- Disclose sponsored content as per FTC/ASCI guidelines\n- Not use bots, fake engagement, or fraudulent methods\n\n2. Brands agree to:\n- Provide clear campaign briefs and expectations\n- Make timely payments for completed work\n- Not request content that violates laws or platform guidelines\n- Respect intellectual property rights of creators\n\n3. All users agree to:\n- Not harass, abuse, or threaten other users\n- Not post misleading, false, or defamatory content\n- Not attempt to circumvent Platform fees by transacting outside the Platform\n- Not use the Platform for any unlawful purpose',
    ),
    LegalSection(
      'Earnings and Withdrawals',
      '1. Creators earn by completing approved campaign and job deliverables. Earnings are credited to your in-app Campster wallet.\n\n2. The Platform does NOT sell any in-app products, coins, subscriptions, or digital goods, and does NOT accept deposits or in-app payments from users.\n\n3. Creator earnings are credited upon campaign/submission approval or after the dispute resolution period (7 days).\n\n4. Withdrawals are requested from your wallet and processed within 3-5 business days to the verified bank account or UPI ID on file.\n\n5. All earnings are subject to applicable taxes. Users are responsible for their own tax obligations.\n\n6. You must provide accurate payout details. The Platform is not responsible for failed transfers caused by incorrect bank or UPI information.',
    ),
    LegalSection(
      'Disputes and Resolution',
      '1. If a brand is not satisfied with campaign deliverables, they may raise a dispute within 7 days of submission.\n\n2. Disputes will be reviewed by our moderation team within 5 business days.\n\n3. During dispute resolution, the related payout is held and not released until the dispute is resolved.\n\n4. Our dispute resolution decision is final.\n\n5. Repeated disputes may affect your platform reputation score and account standing.',
    ),
    LegalSection(
      'Intellectual Property',
      '1. Creators retain ownership of their original content unless otherwise agreed in a specific campaign brief.\n\n2. By posting content on the Platform, you grant us a non-exclusive, worldwide license to display, reproduce, and distribute such content for Platform operation and promotion.\n\n3. Brands receive a license to use creator content as specified in the campaign agreement.\n\n4. You must not infringe on third-party intellectual property rights. Content that violates copyright will be removed.\n\n5. The Campster name, logo, and Platform design are our trademarks and may not be used without permission.',
    ),
    LegalSection(
      'Content Moderation',
      '1. We employ automated AI moderation and manual review to ensure content compliance.\n\n2. Content that violates our Community Guidelines will be removed without notice.\n\n3. Prohibited content includes but is not limited to:\n- Hate speech or discrimination\n- Sexually explicit material\n- Violence or harmful activities\n- Spam or misleading information\n- Illegal products or services\n\n4. Repeated violations will result in warnings, suspension, or permanent account termination.',
    ),
    LegalSection(
      'Account Suspension and Termination',
      '1. We may suspend or terminate your account for:\n- Violation of these Terms\n- Fraudulent activity or fake engagement\n- Inactivity for more than 12 months\n- At our sole discretion for safety or legal reasons\n\n2. Upon termination:\n- Pending payments will be processed according to their status\n- You lose access to all Platform features\n- Your data will be retained per our Privacy Policy\n\n3. You may appeal a suspension through the in-app appeal process within 30 days.',
    ),
    LegalSection(
      'Limitation of Liability',
      '1. The Platform is provided "as is" without warranties of any kind.\n\n2. We are not liable for:\n- Loss of profits or data\n- Campaign outcomes or performance\n- Actions of other users\n- Service interruptions or technical issues\n- Third-party content or links\n\n3. Our total liability is limited to the fees paid to us in the 12 months preceding the claim.\n\n4. We are not responsible for disputes between brands and creators beyond our stated resolution process.',
    ),
    LegalSection(
      'Governing Law',
      'These Terms are governed by and construed in accordance with the laws of India. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts in Jodhpur, Rajasthan, India.',
    ),
    LegalSection(
      'Changes to Terms',
      'We reserve the right to modify these Terms at any time. Material changes will be communicated via email or in-app notification at least 14 days before they take effect. Continued use of the Platform after changes constitutes acceptance of the modified Terms.',
    ),
    LegalSection(
      'Contact Information',
      'For questions about these Terms of Service, please contact us:\n\nEmail: rexoagency.in@gmail.com\nSupport: Available through the Help & Support section in the app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalDocument(
      title: 'Terms of Service',
      lastUpdated: DateFormat('MMMM d, yyyy').format(DateTime.now()),
      sections: _sections,
    );
  }
}
