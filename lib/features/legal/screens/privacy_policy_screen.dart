import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 1, 2024',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Introduction',
              'Welcome to Rexo Marketplace ("we," "our," or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our influencer marketing platform and mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
            ),
            _buildSection(
              context,
              'Information We Collect',
              'We collect information that you voluntarily provide to us when you register on the platform, express an interest in obtaining information about us or our products and services, participate in activities on the platform, or otherwise contact us.\n\nPersonal Information: Name, email address, phone number, date of birth, social media handles, profile photos, and KYC documents (government-issued ID such as Aadhaar, PAN card, or Passport).\n\nFinancial Information: Bank account details, UPI IDs, and payment transaction history necessary for processing payments and withdrawals.\n\nSocial Media Data: We may collect information from your connected social media accounts including follower counts, engagement metrics, content performance data, and audience demographics when you link your accounts for campaign participation.\n\nDevice Information: Device type, operating system version, unique device identifiers, IP address, browser type, and mobile network information.\n\nUsage Data: Information about how you use the platform including pages visited, features used, time spent on pages, search queries, and interaction patterns.',
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              'We use personal information collected via our platform for a variety of business purposes:\n\n1. Account Management: To create and manage your user account, verify your identity through KYC processes, and maintain your profile.\n\n2. Campaign Matching: To match creators with relevant brand campaigns based on your audience demographics, content niche, and performance metrics.\n\n3. Payment Processing: To process deposits, withdrawals, campaign payments, and maintain transaction records.\n\n4. Communication: To send you platform notifications, campaign updates, payment confirmations, and important service announcements.\n\n5. Platform Improvement: To analyze usage patterns, improve features, optimize user experience, and develop new services.\n\n6. Security: To detect and prevent fraud, unauthorized access, and other security incidents. We employ AI-based moderation and device fingerprinting for security purposes.\n\n7. Legal Compliance: To comply with applicable laws, regulatory requirements, and respond to lawful requests from authorities.',
            ),
            _buildSection(
              context,
              'Data Storage and Security',
              'We store your data on secure servers hosted by Supabase with encryption at rest and in transit. Your KYC documents are stored in encrypted cloud storage with strict access controls.\n\nWe implement industry-standard security measures including:\n- End-to-end encryption for sensitive data transmission\n- Role-based access control for internal data access\n- Regular security audits and vulnerability assessments\n- Automated suspicious activity detection\n- Secure session management with device tracking\n\nWhile we strive to use commercially acceptable means to protect your personal information, no method of transmission over the Internet or method of electronic storage is 100% secure.',
            ),
            _buildSection(
              context,
              'Data Sharing and Disclosure',
              'We may share your information in the following situations:\n\n1. With Brands/Creators: When you participate in campaigns, relevant profile information (name, handle, metrics) is shared with the other party to facilitate collaboration.\n\n2. Payment Partners: Financial information is shared with payment processors to facilitate transactions.\n\n3. Service Providers: We may share data with third-party vendors who perform services on our behalf (analytics, hosting, customer support).\n\n4. Legal Requirements: We may disclose information where required by law, regulation, or legal process.\n\n5. Business Transfers: In connection with any merger, acquisition, or sale of company assets.\n\nWe do not sell your personal information to third parties for advertising purposes.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'Depending on your location, you may have the following rights regarding your personal data:\n\n- Right to Access: Request a copy of your personal data.\n- Right to Rectification: Request correction of inaccurate data.\n- Right to Erasure: Request deletion of your personal data (subject to legal retention requirements).\n- Right to Portability: Request transfer of your data in a machine-readable format.\n- Right to Object: Object to processing of your data for certain purposes.\n- Right to Withdraw Consent: Withdraw previously given consent at any time.\n\nTo exercise these rights, contact us at privacy@rexoagency.in. We will respond within 30 days.',
            ),
            _buildSection(
              context,
              'Data Retention',
              'We retain your personal information for as long as your account is active or as needed to provide you services. Financial records are retained for a minimum of 7 years as required by applicable tax and financial regulations. KYC documents are retained for the duration of your account plus 5 years after account closure.',
            ),
            _buildSection(
              context,
              'Children\'s Privacy',
              'Our platform is not intended for users under the age of 18. We do not knowingly collect personal information from anyone under 18 years of age. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            ),
            _buildSection(
              context,
              'Changes to This Policy',
              'We may update this privacy policy from time to time. The updated version will be indicated by an updated "Last Updated" date. We will notify you of material changes through the app or via email. Your continued use of the platform after changes constitutes acceptance of the revised policy.',
            ),
            _buildSection(
              context,
              'Contact Us',
              'If you have questions or concerns about this privacy policy or our data practices, please contact us:\n\nEmail: privacy@rexoagency.in\nAddress: Rexo Agency, India\nSupport: Available through the Help & Support section in the app.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
