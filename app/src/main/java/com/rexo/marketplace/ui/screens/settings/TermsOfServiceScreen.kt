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
 * Terms of Service Screen
 *
 * Displays the complete terms of service for Rexo Marketplace.
 * Covers acceptance, accounts, campaigns, payments, IP, liability, termination, governing law.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsOfServiceScreen(
    onNavigateBack: () -> Unit = {}
) {
    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Terms of Service",
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
                text = "Rexo Marketplace Terms of Service",
                style = RexoTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            Text(
                text = "Last updated: January 2025",
                style = RexoTheme.typography.bodySmall,
                color = RexoColors.TextSecondary
            )

            TermsSection(
                title = "1. Acceptance of Terms",
                content = "By accessing or using the Rexo Marketplace application (\"App\"), you agree " +
                    "to be bound by these Terms of Service (\"Terms\"). If you do not agree to these " +
                    "Terms, you may not access or use the App. These Terms constitute a legally binding " +
                    "agreement between you and Rexo Agency (\"Rexo\", \"we\", \"our\", or \"us\").\n\n" +
                    "We reserve the right to modify these Terms at any time. Changes will be effective " +
                    "upon posting to the App. Your continued use of the App after any modifications " +
                    "constitutes acceptance of the updated Terms."
            )

            TermsSection(
                title = "2. User Accounts",
                content = "To use Rexo, you must create an account. You agree to:\n\n" +
                    "\u2022 Provide accurate and complete registration information.\n\n" +
                    "\u2022 Maintain the security of your account credentials.\n\n" +
                    "\u2022 Notify us immediately of any unauthorized access to your account.\n\n" +
                    "\u2022 Be responsible for all activities that occur under your account.\n\n" +
                    "\u2022 Not create multiple accounts or share your account with others.\n\n" +
                    "You must be at least 18 years old to create an account. We reserve the right to " +
                    "suspend or terminate accounts that violate these Terms or engage in fraudulent activity."
            )

            TermsSection(
                title = "3. Campaign Rules",
                content = "When participating in campaigns on Rexo, you agree to the following rules:\n\n" +
                    "\u2022 Applications: Submit honest and accurate proposals. Misrepresenting your " +
                    "capabilities, follower count, or engagement metrics is prohibited.\n\n" +
                    "\u2022 Deliverables: Complete all campaign deliverables within the agreed timeline " +
                    "and to the specifications provided by the brand.\n\n" +
                    "\u2022 Content Standards: All content created must comply with applicable laws, " +
                    "platform guidelines, and brand requirements. Content must not be misleading, " +
                    "offensive, or infringe on third-party rights.\n\n" +
                    "\u2022 Exclusivity: Respect any exclusivity clauses in campaign agreements. Do not " +
                    "promote competing brands during active exclusivity periods.\n\n" +
                    "\u2022 Disclosure: Comply with all applicable advertising disclosure requirements " +
                    "(e.g., FTC guidelines, ASCI guidelines). Clearly mark sponsored content as such."
            )

            TermsSection(
                title = "4. Payment Terms",
                content = "Rexo facilitates payments between brands and creators. By using our payment " +
                    "system, you agree to the following:\n\n" +
                    "\u2022 Escrow: Campaign funds are held in escrow until deliverables are approved " +
                    "by the brand. This protects both parties.\n\n" +
                    "\u2022 Release: Payments are released to creators after brand approval of deliverables " +
                    "or after the automatic release period (7 business days from submission).\n\n" +
                    "\u2022 Fees: Rexo charges a platform fee of 10% on successful campaign payments. " +
                    "This fee is deducted before funds are credited to your wallet.\n\n" +
                    "\u2022 Withdrawals: Minimum withdrawal amount is INR 500. Withdrawals are processed " +
                    "within 3-5 business days via UPI, bank transfer, or other supported methods.\n\n" +
                    "\u2022 Taxes: You are responsible for paying all applicable taxes on your earnings. " +
                    "Rexo may withhold taxes as required by law.\n\n" +
                    "\u2022 Disputes: Payment disputes must be raised within 14 days of payment release. " +
                    "We will investigate and resolve disputes in good faith."
            )

            TermsSection(
                title = "5. Intellectual Property",
                content = "Ownership and licensing of intellectual property on Rexo:\n\n" +
                    "\u2022 Your Content: You retain ownership of all content you create. By posting " +
                    "content to Rexo or as part of a campaign, you grant Rexo a non-exclusive, worldwide " +
                    "license to display and distribute it within the platform.\n\n" +
                    "\u2022 Campaign Content: Content created for campaigns is subject to the licensing " +
                    "terms agreed upon between you and the brand. Review campaign briefs carefully.\n\n" +
                    "\u2022 Rexo IP: The Rexo name, logo, and all platform features are our intellectual " +
                    "property. You may not use our branding without written permission.\n\n" +
                    "\u2022 DMCA: We respect intellectual property rights. If you believe your content " +
                    "has been infringed, contact us at rexoagency.in@gmail.com with details."
            )

            TermsSection(
                title = "6. Limitation of Liability",
                content = "To the maximum extent permitted by applicable law:\n\n" +
                    "\u2022 Rexo is provided on an \"as is\" and \"as available\" basis without warranties " +
                    "of any kind, express or implied.\n\n" +
                    "\u2022 We do not guarantee uninterrupted, secure, or error-free service.\n\n" +
                    "\u2022 We are not liable for any indirect, incidental, special, consequential, or " +
                    "punitive damages arising from your use of the platform.\n\n" +
                    "\u2022 Our total liability shall not exceed the amount paid by or to you through " +
                    "Rexo in the 12 months preceding the claim.\n\n" +
                    "\u2022 We are not responsible for the actions, content, or reliability of third " +
                    "parties, including brands, creators, and payment processors.\n\n" +
                    "\u2022 You use the platform at your own risk and agree to hold Rexo harmless from " +
                    "any claims arising from your use."
            )

            TermsSection(
                title = "7. Termination",
                content = "Either party may terminate the relationship:\n\n" +
                    "\u2022 You may delete your account at any time through the app settings.\n\n" +
                    "\u2022 We may suspend or terminate your account if you violate these Terms, " +
                    "engage in fraudulent activity, or at our sole discretion with reasonable notice.\n\n" +
                    "\u2022 Upon termination, any pending payments for completed work will be processed. " +
                    "Uncompleted campaigns will be canceled.\n\n" +
                    "\u2022 Sections regarding intellectual property, limitation of liability, and " +
                    "governing law survive termination.\n\n" +
                    "\u2022 If your account is terminated for violation, you may not create a new account " +
                    "without our written permission."
            )

            TermsSection(
                title = "8. Governing Law",
                content = "These Terms shall be governed by and construed in accordance with the laws " +
                    "of India, without regard to conflict of law principles. Any disputes arising from " +
                    "these Terms or your use of Rexo shall be subject to the exclusive jurisdiction of " +
                    "the courts in Bangalore, Karnataka, India.\n\n" +
                    "Before initiating legal proceedings, you agree to attempt to resolve disputes " +
                    "through good-faith negotiation by contacting us at rexoagency.in@gmail.com. " +
                    "If negotiations fail after 30 days, either party may pursue legal remedies."
            )

            TermsSection(
                title = "9. Contact Information",
                content = "If you have questions about these Terms of Service, please contact us:\n\n" +
                    "Email: rexoagency.in@gmail.com\n" +
                    "Platform: Rexo Marketplace\n" +
                    "Response Time: We aim to respond within 48 hours."
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun TermsSection(
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
