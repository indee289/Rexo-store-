package com.rexo.marketplace.ui.screens.settings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Help & Support Screen
 *
 * Contains:
 * - FAQ section with expandable items
 * - Support email with copy button
 * - Contact information
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HelpSupportScreen(
    onNavigateBack: () -> Unit = {}
) {
    val clipboardManager = LocalClipboardManager.current
    var copiedEmail by remember { mutableStateOf(false) }

    Scaffold(
        containerColor = Color.White,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Help & Support",
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
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Contact section
            Text(
                text = "Contact Us",
                style = RexoTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            // Support email card
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = Color.White,
                border = BorderStroke(1.dp, RexoColors.CardBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            Icons.Outlined.Email,
                            contentDescription = "Email",
                            tint = RexoColors.AccentOrange,
                            modifier = Modifier.size(24.dp)
                        )
                        Column {
                            Text(
                                text = "Email Support",
                                style = RexoTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = RexoColors.TextPrimary
                            )
                            Text(
                                text = "support@rexo.in",
                                style = RexoTheme.typography.bodySmall,
                                color = RexoColors.TextSecondary
                            )
                        }
                    }

                    Button(
                        onClick = {
                            clipboardManager.setText(AnnotatedString("support@rexo.in"))
                            copiedEmail = true
                        },
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (copiedEmail) RexoColors.Success else RexoColors.AccentOrange
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                    ) {
                        Icon(
                            imageVector = if (copiedEmail) Icons.Outlined.Check else Icons.Outlined.ContentCopy,
                            contentDescription = "Copy",
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = if (copiedEmail) "Copied" else "Copy",
                            style = RexoTheme.typography.labelSmall
                        )
                    }
                }
            }

            // Response time
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = RexoColors.Gray50
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Outlined.AccessTime,
                        contentDescription = null,
                        tint = RexoColors.AccentOrange,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "We typically respond within 24-48 hours",
                        style = RexoTheme.typography.bodySmall,
                        color = RexoColors.TextSecondary
                    )
                }
            }

            // FAQ Section
            Text(
                text = "Frequently Asked Questions",
                style = RexoTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = RexoColors.TextPrimary
            )

            FAQItem(
                question = "How do I apply to campaigns?",
                answer = "Browse available campaigns on the Campaigns tab. Tap on a campaign to view details, " +
                    "then tap 'Apply Now' to submit your proposal with your rate and pitch. You will be " +
                    "notified when the brand reviews your application."
            )

            FAQItem(
                question = "How do payments work?",
                answer = "When a brand approves your campaign deliverables, the payment is released to your " +
                    "Rexo wallet. You can withdraw funds to your bank account or UPI. Minimum withdrawal " +
                    "amount is INR 500, and processing takes 3-5 business days."
            )

            FAQItem(
                question = "How do I create my media kit?",
                answer = "Go to Services > Media Kit to generate your media kit. It automatically pulls your " +
                    "stats from your creator profile including followers, engagement rate, and completed " +
                    "campaigns. You can share it directly with brands."
            )

            FAQItem(
                question = "What happens if a campaign is cancelled?",
                answer = "If a campaign is cancelled before you submit deliverables, no payment is made. " +
                    "If you have already submitted deliverables, the brand must still review and approve " +
                    "them, or the payment will auto-release after 7 business days."
            )

            FAQItem(
                question = "How do I update my profile?",
                answer = "Tap on the Profile tab to view and edit your profile information. You can update " +
                    "your bio, social media handles, category, and profile picture. Make sure to keep your " +
                    "stats updated for accurate media kit generation."
            )

            FAQItem(
                question = "How is the rate calculator formula computed?",
                answer = "The rate calculator uses the formula: (Followers / 1000) x Engagement Rate x " +
                    "Platform Multiplier. Platform multipliers are: Instagram (1.5x), YouTube (2.0x), " +
                    "TikTok (1.2x). The result is your suggested rate per post."
            )

            FAQItem(
                question = "Can I work with multiple brands at once?",
                answer = "Yes! You can apply to and work on multiple campaigns simultaneously, as long as " +
                    "there are no exclusivity clauses in your active agreements. Check each campaign's " +
                    "terms before applying."
            )

            FAQItem(
                question = "How do I report an issue with a brand?",
                answer = "If you encounter issues with a brand (non-payment, inappropriate requests, etc.), " +
                    "contact our support team at support@rexo.in with details of the issue. Include your " +
                    "campaign ID and any relevant screenshots. We take all reports seriously."
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    // Reset copy state after delay
    LaunchedEffect(copiedEmail) {
        if (copiedEmail) {
            kotlinx.coroutines.delay(2000)
            copiedEmail = false
        }
    }
}

@Composable
private fun FAQItem(
    question: String,
    answer: String
) {
    var expanded by remember { mutableStateOf(false) }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded },
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.dp, RexoColors.CardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = question,
                    style = RexoTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = RexoColors.TextPrimary,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    imageVector = if (expanded) Icons.Outlined.ExpandLess else Icons.Outlined.ExpandMore,
                    contentDescription = if (expanded) "Collapse" else "Expand",
                    tint = RexoColors.Gray400,
                    modifier = Modifier.size(20.dp)
                )
            }

            AnimatedVisibility(visible = expanded) {
                Text(
                    text = answer,
                    style = RexoTheme.typography.bodySmall,
                    color = RexoColors.TextSecondary,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }
        }
    }
}
