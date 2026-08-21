package com.rexo.marketplace.navigation

import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.rexo.marketplace.ui.screens.admin.AdminScreen
import com.rexo.marketplace.ui.screens.auth.AuthScreen
import com.rexo.marketplace.ui.screens.campaigns.CampaignDetailScreen
import com.rexo.marketplace.ui.screens.campaigns.CampaignsScreen
import com.rexo.marketplace.ui.screens.chat.ChatDetailScreen
import com.rexo.marketplace.ui.screens.chat.ChatListScreen
import com.rexo.marketplace.ui.screens.home.HomeScreen
import com.rexo.marketplace.ui.screens.notifications.NotificationsScreen
import com.rexo.marketplace.ui.screens.profile.ProfileScreen
import com.rexo.marketplace.ui.screens.settings.HelpSupportScreen
import com.rexo.marketplace.ui.screens.settings.PrivacyPolicyScreen
import com.rexo.marketplace.ui.screens.settings.SettingsScreen
import com.rexo.marketplace.ui.screens.settings.TermsOfServiceScreen
import com.rexo.marketplace.ui.screens.shop.CartScreen
import com.rexo.marketplace.ui.screens.shop.CheckoutScreen
import com.rexo.marketplace.ui.screens.shop.MyPurchasesScreen
import com.rexo.marketplace.ui.screens.shop.ProductDetailScreen
import com.rexo.marketplace.ui.screens.shop.ShopScreen
import com.rexo.marketplace.ui.screens.services.ServicesScreen
import com.rexo.marketplace.ui.screens.wallet.WalletScreen
import com.rexo.marketplace.ui.theme.RexoColors
import com.rexo.marketplace.ui.viewmodel.AuthUiState
import com.rexo.marketplace.ui.viewmodel.AuthViewModel
import com.rexo.marketplace.ui.viewmodel.CampaignViewModel
import com.rexo.marketplace.ui.viewmodel.ChatViewModel
import com.rexo.marketplace.ui.viewmodel.NotificationViewModel
import com.rexo.marketplace.ui.viewmodel.ShopViewModel

/**
 * Navigation Graph for Rexo App
 * Handles routing between all screens with smooth animations
 */

// Route definitions
sealed class Screen(val route: String) {
    object Auth : Screen("auth")
    object Home : Screen("home")
    object Campaigns : Screen("campaigns")
    object CampaignDetail : Screen("campaign_detail/{campaignId}") {
        fun createRoute(campaignId: String) = "campaign_detail/$campaignId"
    }
    object Wallet : Screen("wallet")
    object Notifications : Screen("notifications")
    object Profile : Screen("profile")
    object Settings : Screen("settings")
    object Admin : Screen("admin")
    object Shop : Screen("shop")
    object ProductDetail : Screen("product_detail/{productId}") {
        fun createRoute(productId: String) = "product_detail/$productId"
    }
    object Cart : Screen("cart")
    object Checkout : Screen("checkout")
    object MyOrders : Screen("my_orders")
    object Services : Screen("services")
    object PrivacyPolicy : Screen("privacy_policy")
    object ChatList : Screen("chat_list")
    object ChatDetail : Screen("chat_detail/{recipientId}") {
        fun createRoute(recipientId: String) = "chat_detail/$recipientId"
    }
    object TermsOfService : Screen("terms_of_service")
    object HelpSupport : Screen("help_support")
}

// Bottom navigation items - 4 tabs
sealed class BottomNavItem(
    val route: String,
    val title: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    object Home : BottomNavItem(
        route = Screen.Home.route,
        title = "Home",
        selectedIcon = Icons.Filled.Home,
        unselectedIcon = Icons.Outlined.Home
    )

    object Campaigns : BottomNavItem(
        route = Screen.Campaigns.route,
        title = "Campaigns",
        selectedIcon = Icons.Filled.Campaign,
        unselectedIcon = Icons.Outlined.Campaign
    )

    object Shop : BottomNavItem(
        route = Screen.Shop.route,
        title = "Shop",
        selectedIcon = Icons.Filled.ShoppingCart,
        unselectedIcon = Icons.Outlined.ShoppingCart
    )

    object Profile : BottomNavItem(
        route = Screen.Profile.route,
        title = "Profile",
        selectedIcon = Icons.Filled.Person,
        unselectedIcon = Icons.Outlined.Person
    )
}

@Composable
fun RexoNavGraph(
    navController: NavHostController = rememberNavController(),
    startDestination: String = Screen.Auth.route,
    authViewModel: AuthViewModel = viewModel(),
    campaignViewModel: CampaignViewModel = viewModel(),
    notificationViewModel: NotificationViewModel = viewModel(),
    shopViewModel: ShopViewModel = viewModel(),
    chatViewModel: ChatViewModel = viewModel()
) {
    NavHost(
        navController = navController,
        startDestination = startDestination,
        enterTransition = {
            slideInHorizontally(
                initialOffsetX = { it },
                animationSpec = tween(300)
            ) + fadeIn(animationSpec = tween(300))
        },
        exitTransition = {
            slideOutHorizontally(
                targetOffsetX = { -it / 2 },
                animationSpec = tween(300)
            ) + fadeOut(animationSpec = tween(300))
        },
        popEnterTransition = {
            slideInHorizontally(
                initialOffsetX = { -it / 2 },
                animationSpec = tween(300)
            ) + fadeIn(animationSpec = tween(300))
        },
        popExitTransition = {
            slideOutHorizontally(
                targetOffsetX = { it },
                animationSpec = tween(300)
            ) + fadeOut(animationSpec = tween(300))
        }
    ) {
        // Auth Screen
        composable(Screen.Auth.route) {
            AuthScreen(
                onNavigateToHome = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                },
                authViewModel = authViewModel
            )
        }

        // Home Screen (Discover)
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToWallet = {
                    navController.navigate(Screen.Wallet.route)
                },
                onNavigateToCampaigns = {
                    navController.navigate(Screen.Campaigns.route)
                },
                onNavigateToProfile = {
                    navController.navigate(Screen.Profile.route)
                },
                onNavigateToNotifications = {
                    navController.navigate(Screen.Notifications.route)
                },
                campaignViewModel = campaignViewModel
            )
        }

        // Campaigns Screen
        composable(Screen.Campaigns.route) {
            CampaignsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToCampaignDetail = { campaignId ->
                    navController.navigate(Screen.CampaignDetail.createRoute(campaignId))
                },
                campaignViewModel = campaignViewModel
            )
        }

        // Campaign Detail Screen
        composable(
            route = Screen.CampaignDetail.route,
            arguments = listOf(navArgument("campaignId") { type = NavType.StringType })
        ) { backStackEntry ->
            val campaignId = backStackEntry.arguments?.getString("campaignId") ?: ""
            CampaignDetailScreen(
                campaignId = campaignId,
                onNavigateBack = { navController.popBackStack() },
                campaignViewModel = campaignViewModel
            )
        }

        // Wallet Screen
        composable(Screen.Wallet.route) {
            WalletScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Notifications Screen
        composable(Screen.Notifications.route) {
            NotificationsScreen(
                onNavigateBack = { navController.popBackStack() },
                viewModel = notificationViewModel
            )
        }

        // Profile Screen
        composable(Screen.Profile.route) {
            val isAdmin by authViewModel.isAdmin.collectAsState()
            ProfileScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onNavigateToAdmin = {
                    navController.navigate(Screen.Admin.route)
                },
                onNavigateToPrivacyPolicy = {
                    navController.navigate(Screen.PrivacyPolicy.route)
                },
                onNavigateToWallet = {
                    navController.navigate(Screen.Wallet.route)
                },
                onNavigateToNotifications = {
                    navController.navigate(Screen.Notifications.route)
                },
                onSignOut = {
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(0) { inclusive = true }
                    }
                },
                isAdmin = isAdmin
            )
        }

        // Settings Screen
        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToPrivacyPolicy = {
                    navController.navigate(Screen.PrivacyPolicy.route)
                },
                onNavigateToTermsOfService = {
                    navController.navigate(Screen.TermsOfService.route)
                },
                onNavigateToHelpSupport = {
                    navController.navigate(Screen.HelpSupport.route)
                },
                onSignOut = {
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }

        // Privacy Policy Screen
        composable(Screen.PrivacyPolicy.route) {
            PrivacyPolicyScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Terms of Service Screen
        composable(Screen.TermsOfService.route) {
            TermsOfServiceScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Help & Support Screen
        composable(Screen.HelpSupport.route) {
            HelpSupportScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Admin Screen - Protected: only accessible to admin role users
        composable(Screen.Admin.route) {
            val isAdmin by authViewModel.isAdmin.collectAsState()
            if (isAdmin) {
                AdminScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            } else {
                // Non-admin users are redirected back
                LaunchedEffect(Unit) {
                    navController.popBackStack()
                }
            }
        }

        // Shop Screen
        composable(Screen.Shop.route) {
            ShopScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToProductDetail = { productId ->
                    navController.navigate(Screen.ProductDetail.createRoute(productId))
                },
                onNavigateToCart = {
                    navController.navigate(Screen.Cart.route)
                },
                onNavigateToOrders = {
                    navController.navigate(Screen.MyOrders.route)
                },
                viewModel = shopViewModel
            )
        }

        // Product Detail Screen
        composable(
            route = Screen.ProductDetail.route,
            arguments = listOf(navArgument("productId") { type = NavType.StringType })
        ) { backStackEntry ->
            val productId = backStackEntry.arguments?.getString("productId") ?: ""
            ProductDetailScreen(
                productId = productId,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToCart = {
                    navController.navigate(Screen.Cart.route)
                },
                viewModel = shopViewModel
            )
        }

        // Cart Screen
        composable(Screen.Cart.route) {
            CartScreen(
                onNavigateBack = { navController.popBackStack() },
                onCheckout = {
                    navController.navigate(Screen.Checkout.route)
                },
                viewModel = shopViewModel
            )
        }

        // Checkout Screen
        composable(Screen.Checkout.route) {
            CheckoutScreen(
                onNavigateBack = { navController.popBackStack() },
                onOrderPlaced = {
                    navController.navigate(Screen.MyOrders.route) {
                        popUpTo(Screen.Shop.route) { inclusive = false }
                    }
                },
                viewModel = shopViewModel
            )
        }

        // My Orders Screen
        composable(Screen.MyOrders.route) {
            MyPurchasesScreen(
                onNavigateBack = { navController.popBackStack() },
                viewModel = shopViewModel
            )
        }

        // Services Screen - Tools and utilities
        composable(Screen.Services.route) {
            ServicesScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Chat List Screen
        composable(Screen.ChatList.route) {
            ChatListScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToChat = { recipientId ->
                    navController.navigate(Screen.ChatDetail.createRoute(recipientId))
                },
                viewModel = chatViewModel
            )
        }

        // Chat Detail Screen
        composable(
            route = Screen.ChatDetail.route,
            arguments = listOf(navArgument("recipientId") { type = NavType.StringType })
        ) { backStackEntry ->
            val recipientId = backStackEntry.arguments?.getString("recipientId") ?: ""
            ChatDetailScreen(
                recipientId = recipientId,
                onNavigateBack = { navController.popBackStack() },
                viewModel = chatViewModel
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlaceholderScreen(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onNavigateBack: () -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(title) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = title,
                style = MaterialTheme.typography.headlineMedium
            )

            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Coming Soon",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

/**
 * Main App Scaffold with Bottom Navigation.
 * Determines start destination based on auth state.
 * Controls admin access based on user role.
 */
@Composable
fun MainScaffold() {
    val authViewModel: AuthViewModel = viewModel()
    val campaignViewModel: CampaignViewModel = viewModel()
    val notificationViewModel: NotificationViewModel = viewModel()
    val shopViewModel: ShopViewModel = viewModel()
    val chatViewModel: ChatViewModel = viewModel()
    val uiState by authViewModel.uiState.collectAsState()
    val isAdmin by authViewModel.isAdmin.collectAsState()
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Determine start destination based on auth state
    val startDestination = remember(uiState) {
        when (uiState) {
            is AuthUiState.Authenticated -> Screen.Home.route
            else -> Screen.Auth.route
        }
    }

    // Show loading while checking auth
    if (uiState is AuthUiState.Loading && currentRoute == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(
                color = MaterialTheme.colorScheme.primary
            )
        }
        return
    }

    // Determine if bottom bar should be visible
    val showBottomBar = currentRoute in listOf(
        Screen.Home.route,
        Screen.Campaigns.route,
        Screen.Shop.route,
        Screen.Profile.route
    )

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        bottomBar = {
            if (showBottomBar) {
                FloatingPillBottomNavigation(
                    navController = navController,
                    currentRoute = currentRoute,
                    isAdmin = isAdmin
                )
            }
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues)) {
            RexoNavGraph(
                navController = navController,
                startDestination = startDestination,
                authViewModel = authViewModel,
                campaignViewModel = campaignViewModel,
                notificationViewModel = notificationViewModel,
                shopViewModel = shopViewModel,
                chatViewModel = chatViewModel
            )
        }
    }
}

/**
 * Floating Pill-Style Bottom Navigation
 *
 * Premium design:
 * - Floating container with 28dp corner radius
 * - White background with subtle shadow (6dp elevation)
 * - 16dp horizontal margin from screen edges
 * - Active tab gets pill-shaped background with orange accent
 * - Active tab shows icon + label inside the pill
 * - Inactive tabs show only icon
 */
@Composable
fun FloatingPillBottomNavigation(
    navController: NavHostController,
    currentRoute: String?,
    isAdmin: Boolean = false
) {
    val items = listOf(
        BottomNavItem.Home,
        BottomNavItem.Campaigns,
        BottomNavItem.Shop,
        BottomNavItem.Profile
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(
                    elevation = 6.dp,
                    shape = RoundedCornerShape(28.dp),
                    clip = false
                )
                .clip(RoundedCornerShape(28.dp))
                .background(Color.White)
                .padding(horizontal = 12.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            items.forEach { item ->
                val selected = currentRoute == item.route

                if (selected) {
                    // Active tab - pill with icon + label
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(24.dp))
                            .background(RexoColors.AccentOrange.copy(alpha = 0.12f))
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null
                            ) {
                                // Already on this tab
                            }
                            .padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = item.selectedIcon,
                            contentDescription = item.title,
                            tint = RexoColors.AccentOrange,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = item.title,
                            color = RexoColors.AccentOrange,
                            fontSize = 13.sp,
                            style = MaterialTheme.typography.labelMedium
                        )
                    }
                } else {
                    // Inactive tab - icon only
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(24.dp))
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null
                            ) {
                                navController.navigate(item.route) {
                                    popUpTo(Screen.Home.route) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                            .padding(12.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = item.unselectedIcon,
                            contentDescription = item.title,
                            tint = RexoColors.Gray400,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ModernBottomNavigation(
    navController: NavHostController,
    currentRoute: String?,
    isAdmin: Boolean = false
) {
    // Delegate to the floating pill style
    FloatingPillBottomNavigation(
        navController = navController,
        currentRoute = currentRoute,
        isAdmin = isAdmin
    )
}
