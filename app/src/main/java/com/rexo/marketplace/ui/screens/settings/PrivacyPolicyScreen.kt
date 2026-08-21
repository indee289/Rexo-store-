package com.rexo.marketplace.ui.screens.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Privacy Policy Screen
 *
 * Displays the real privacy policy content for Rexo Marketplace.
 * Covers data collection, usage, sharing, user rights, and contact info.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacyPolicyScreen(
    onNavigateBack: () -> Unit = {}
) {
    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Privacy Policy",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = RexoColors.TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            Icons.Outlined.ArrowBack,
                            contentDescription = "Back",
                            tint = RexoColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Rexo Marketplace Privacy Policy",
                style = RexoTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Text(
                text = "Last updated: January 2025",
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary
            )

            PolicySection(
                title = "1. Introduction",
                content = "Welcome to Rexo Marketplace (\"Rexo\", \"we\", \"our\", or \"us\"). " +
                    "Rexo is a creator marketplace platform that connects brands with content creators " +
                    "for sponsored campaigns, collaborations, and influencer marketing. This Privacy Policy " +
                    "explains how we collect, use, disclose, and safeguard your information when you use " +
                    "our mobile application and services. Please read this policy carefully. By accessing " +
                    "or using Rexo, you agree to the practices described in this policy."
            )

            PolicySection(
                title = "2. Information We Collect",
                content = "We collect information that you provide directly to us, including:\n\n" +
                    "\u2022 Account Information: When you register, we collect your full name, email address, " +
                    "phone number, and password. For creators, we may also collect your social media handles, " +
                    "follower counts, and niche/category information.\n\n" +
                    "\u2022 Profile Information: Your bio, profile picture, location, portfolio links, and " +
                    "connected social media accounts (Instagram, YouTube, TikTok).\n\n" +
                    "\u2022 Identity Verification (KYC): For payment processing, we may collect government-issued " +
                    "identification documents, PAN card details, bank account information, and UPI IDs.\n\n" +
                    "\u2022 Financial Information: Transaction history, wallet balances, payout details, and " +
                    "deposit records necessary for processing payments.\n\n" +
                    "\u2022 Campaign Data: Applications submitted, proposals written, deliverables uploaded, " +
                    "and campaign performance metrics.\n\n" +
                    "\u2022 Usage Data: We automatically collect device information, IP address, app usage " +
                    "patterns, crash logs, and interaction data to improve our services."
            )

            PolicySection(
                title = "3. How We Use Your Information",
                content = "We use the information we collect for the following purposes:\n\n" +
                    "\u2022 To create and manage your account and profile on Rexo.\n\n" +
                    "\u2022 To facilitate connections between brands and creators for campaigns.\n\n" +
                    "\u2022 To process financial transactions including deposits, earnings, and withdrawals.\n\n" +
                    "\u2022 To verify your identity for payment compliance and fraud prevention.\n\n" +
                    "\u2022 To send notifications about campaign updates, payments, and platform announcements.\n\n" +
                    "\u2022 To improve our platform, fix bugs, and develop new features.\n\n" +
                    "\u2022 To enforce our Terms of Service and protect against unauthorized access.\n\n" +
                    "\u2022 To comply with legal obligations and regulatory requirements."
            )

            PolicySection(
                title = "4. Information Sharing and Disclosure",
                content = "We do not sell your personal information. We may share your information in " +
                    "the following circumstances:\n\n" +
                    "\u2022 With Brands: When you apply to or participate in a campaign, relevant profile " +
                    "information (name, handle, engagement metrics) is shared with the brand.\n\n" +
                    "\u2022 Service Providers: We use third-party services for authentication (Supabase), " +
                    "cloud infrastructure, analytics, and payment processing. These providers access data " +
                    "only to perform services on our behalf.\n\n" +
                    "\u2022 Legal Compliance: We may disclose information when required by law, court order, " +
                    "or government regulation, or to protect our rights, safety, or property.\n\n" +
                    "\u2022 Business Transfers: In the event of a merger, acquisition, or sale of assets, " +
                    "user information may be transferred to the successor entity."
            )

            PolicySection(
                title = "5. Data Security",
                content = "We implement industry-standard security measures to protect your data:\n\n" +
                    "\u2022 All data in transit is encrypted using TLS/SSL.\n\n" +
                    "\u2022 Passwords are hashed and never stored in plain text.\n\n" +
                    "\u2022 Access to personal data is restricted to authorized personnel only.\n\n" +
                    "\u2022 We conduct regular security audits and vulnerability assessments.\n\n" +
                    "\u2022 KYC documents are stored securely with access controls.\n\n" +
                    "However, no method of electronic transmission or storage is 100% secure. While we " +
                    "strive to use commercially acceptable means to protect your data, we cannot guarantee " +
                    "absolute security."
            )

            PolicySection(
                title = "6. Data Retention",
                content = "We retain your personal information for as long as your account is active or " +
                    "as needed to provide our services. If you delete your account, we will delete or " +
                    "anonymize your personal data within 30 days, except where we are required to retain " +
                    "it for legal, tax, or compliance purposes (typically 5-7 years for financial records)."
            )

            PolicySection(
                title = "7. Your Rights",
                content = "You have the following rights regarding your personal information:\n\n" +
                    "\u2022 Access: You can request a copy of the personal data we hold about you.\n\n" +
                    "\u2022 Correction: You can update or correct inaccurate information in your profile settings.\n\n" +
                    "\u2022 Deletion: You can request deletion of your account and associated data.\n\n" +
                    "\u2022 Portability: You can request your data in a machine-readable format.\n\n" +
                    "\u2022 Opt-out: You can opt out of marketing emails and push notifications in Settings.\n\n" +
                    "\u2022 Withdraw Consent: You can withdraw consent for data processing at any time, " +
                    "though this may limit your ability to use certain features."
            )

            PolicySection(
                title = "8. Children's Privacy",
                content = "Rexo is not intended for individuals under 18 years of age. We do not knowingly " +
                    "collect personal information from minors. If we become aware that we have collected " +
                    "data from a person under 18, we will take steps to delete such information promptly."
            )

            PolicySection(
                title = "9. Third-Party Links",
                content = "Our platform may contain links to third-party websites and services (e.g., " +
                    "Instagram, YouTube, payment gateways). We are not responsible for the privacy " +
                    "practices of these external sites. We encourage you to review the privacy policies " +
                    "of any third-party services you interact with."
            )

            PolicySection(
                title = "10. Changes to This Policy",
                content = "We may update this Privacy Policy from time to time. We will notify you of " +
                    "significant changes through the app or via email. Your continued use of Rexo after " +
                    "changes are posted constitutes acceptance of the updated policy."
            )

            PolicySection(
                title = "11. Contact Us",
                content = "If you have questions, concerns, or requests regarding this Privacy Policy " +
                    "or our data practices, please contact us at:\n\n" +
                    "Email: rexoagency.in@gmail.com\n" +
                    "Platform: Rexo Marketplace\n" +
                    "Response Time: We aim to respond within 48 hours."
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun PolicySection(
    title: String,
    content: String
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = title,
            style = RexoTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = RexoColors.TextPrimary
        )
        Text(
            text = content,
            style = RexoTheme.typography.bodyMedium,
            color = RexoColors.TextSecondary,
            lineHeight = RexoTheme.typography.bodyMedium.lineHeight
        )
    }
}
