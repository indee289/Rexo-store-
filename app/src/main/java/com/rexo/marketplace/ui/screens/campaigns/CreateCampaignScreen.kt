package com.rexo.marketplace.ui.screens.campaigns

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.rexo.marketplace.ui.components.FloatingGlassCard
import com.rexo.marketplace.ui.components.GlassSurface
import com.rexo.marketplace.ui.theme.RexoTheme

/**
 * Create Campaign Screen
 * Features:
 * - Campaign creation form
 * - Budget settings
 * - Target audience
 * - Deliverables definition
 * - Preview before posting
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateCampaignScreen(
    onNavigateBack: () -> Unit = {},
    onPublish: () -> Unit = {}
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var budget by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("Fashion") }
    var platform by remember { mutableStateOf("Instagram") }
    var deliverables by remember { mutableStateOf("") }
    var requirements by remember { mutableStateOf("") }
    var deadline by remember { mutableStateOf("") }
    
    var showCategoryMenu by remember { mutableStateOf(false) }
    var showPlatformMenu by remember { mutableStateOf(false) }
    
    val categories = listOf("Fashion", "Tech", "Food", "Travel", "Fitness", "Beauty", "Gaming", "Lifestyle")
    val platforms = listOf("Instagram", "YouTube", "Twitter", "TikTok", "Facebook", "LinkedIn")
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Create Campaign",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.Close, contentDescription = "Close")
                    }
                },
                actions = {
                    TextButton(onClick = { /* TODO: Save draft */ }) {
                        Text("Save Draft")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        bottomBar = {
            Surface(
                shadowElevation = 8.dp,
                color = RexoTheme.colorScheme.surface
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = { /* TODO: Preview */ },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Visibility,
                            contentDescription = "Preview",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Preview")
                    }
                    
                    Button(
                        onClick = onPublish,
                        modifier = Modifier.weight(1f),
                        enabled = title.isNotEmpty() && description.isNotEmpty() && budget.isNotEmpty(),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Send,
                            contentDescription = "Publish",
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Publish Campaign")
                    }
                }
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Basic Info
            item {
                Text(
                    text = "Basic Information",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        OutlinedTextField(
                            value = title,
                            onValueChange = { title = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Campaign Title") },
                            placeholder = { Text("e.g., Summer Fashion Collection Launch") },
                            leadingIcon = {
                                Icon(Icons.Outlined.Title, contentDescription = null)
                            },
                            singleLine = true
                        )
                        
                        OutlinedTextField(
                            value = description,
                            onValueChange = { description = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Description") },
                            placeholder = { Text("Describe your campaign in detail...") },
                            leadingIcon = {
                                Icon(Icons.Outlined.Description, contentDescription = null)
                            },
                            minLines = 4,
                            maxLines = 6
                        )
                    }
                }
            }
            
            // Category & Platform
            item {
                Text(
                    text = "Category & Platform",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // Category Dropdown
                        ExposedDropdownMenuBox(
                            expanded = showCategoryMenu,
                            onExpandedChange = { showCategoryMenu = it }
                        ) {
                            OutlinedTextField(
                                value = category,
                                onValueChange = {},
                                readOnly = true,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor(),
                                label = { Text("Category") },
                                trailingIcon = {
                                    Icon(
                                        if (showCategoryMenu) Icons.Outlined.KeyboardArrowUp else Icons.Outlined.KeyboardArrowDown,
                                        contentDescription = "Category"
                                    )
                                },
                                leadingIcon = {
                                    Icon(Icons.Outlined.Category, contentDescription = null)
                                }
                            )
                            
                            ExposedDropdownMenu(
                                expanded = showCategoryMenu,
                                onDismissRequest = { showCategoryMenu = false }
                            ) {
                                categories.forEach { cat ->
                                    DropdownMenuItem(
                                        text = { Text(cat) },
                                        onClick = {
                                            category = cat
                                            showCategoryMenu = false
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Platform Dropdown
                        ExposedDropdownMenuBox(
                            expanded = showPlatformMenu,
                            onExpandedChange = { showPlatformMenu = it }
                        ) {
                            OutlinedTextField(
                                value = platform,
                                onValueChange = {},
                                readOnly = true,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor(),
                                label = { Text("Target Platform") },
                                trailingIcon = {
                                    Icon(
                                        if (showPlatformMenu) Icons.Outlined.KeyboardArrowUp else Icons.Outlined.KeyboardArrowDown,
                                        contentDescription = "Platform"
                                    )
                                },
                                leadingIcon = {
                                    Icon(Icons.Outlined.Smartphone, contentDescription = null)
                                }
                            )
                            
                            ExposedDropdownMenu(
                                expanded = showPlatformMenu,
                                onDismissRequest = { showPlatformMenu = false }
                            ) {
                                platforms.forEach { plat ->
                                    DropdownMenuItem(
                                        text = { Text(plat) },
                                        onClick = {
                                            platform = plat
                                            showPlatformMenu = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            
            // Budget & Timeline
            item {
                Text(
                    text = "Budget & Timeline",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        OutlinedTextField(
                            value = budget,
                            onValueChange = { budget = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Budget per Creator") },
                            placeholder = { Text("₹ 0") },
                            leadingIcon = {
                                Icon(Icons.Outlined.CurrencyRupee, contentDescription = null)
                            },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true
                        )
                        
                        OutlinedTextField(
                            value = deadline,
                            onValueChange = { deadline = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Deadline (days)") },
                            placeholder = { Text("e.g., 7") },
                            leadingIcon = {
                                Icon(Icons.Outlined.CalendarMonth, contentDescription = null)
                            },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            singleLine = true
                        )
                    }
                }
            }
            
            // Deliverables
            item {
                Text(
                    text = "Deliverables & Requirements",
                    style = RexoTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
            
            item {
                FloatingGlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        OutlinedTextField(
                            value = deliverables,
                            onValueChange = { deliverables = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Expected Deliverables") },
                            placeholder = { Text("e.g., 3 Instagram posts, 5 stories...") },
                            leadingIcon = {
                                Icon(Icons.Outlined.CheckCircle, contentDescription = null)
                            },
                            minLines = 3
                        )
                        
                        OutlinedTextField(
                            value = requirements,
                            onValueChange = { requirements = it },
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text("Creator Requirements") },
                            placeholder = { Text("Min followers, engagement rate, etc...") },
                            leadingIcon = {
                                Icon(Icons.Outlined.PersonSearch, contentDescription = null)
                            },
                            minLines = 3
                        )
                    }
                }
            }
            
            // Campaign Preview Card
            if (title.isNotEmpty() && budget.isNotEmpty()) {
                item {
                    Text(
                        text = "Campaign Preview",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                item {
                    CampaignPreviewCard(
                        title = title,
                        category = category,
                        platform = platform,
                        budget = budget.toDoubleOrNull() ?: 0.0,
                        description = description
                    )
                }
            }
            
            // Spacer for bottom bar
            item {
                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }
}

@Composable
fun CampaignPreviewCard(
    title: String,
    category: String,
    platform: String,
    budget: Double,
    description: String
) {
    FloatingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        backgroundColor = RexoTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = Color(0xFF6366F1).copy(alpha = 0.15f)
                ) {
                    Text(
                        text = category,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF6366F1)
                    )
                }
                
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = RexoTheme.colorScheme.primaryContainer
                ) {
                    Text(
                        text = platform,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        style = RexoTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Text(
                text = title,
                style = RexoTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            if (description.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = description.take(100) + if (description.length > 100) "..." else "",
                    style = RexoTheme.typography.bodyMedium,
                    color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Budget",
                        style = RexoTheme.typography.labelMedium,
                        color = RexoTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = "₹${String.format("%,.0f", budget)}",
                        style = RexoTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF10B981)
                    )
                }
                
                Icon(
                    imageVector = Icons.Outlined.Visibility,
                    contentDescription = "Preview",
                    tint = RexoTheme.colorScheme.primary
                )
            }
        }
    }
}
