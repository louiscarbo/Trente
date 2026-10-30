package app.trente.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import app.trente.core.presentation.OnboardingGate
import app.trente.core.services.DeepLink
import app.trente.core.services.MonthService
import app.trente.ui.screens.AboutDeveloperScreen
import app.trente.ui.screens.CreditsScreen
import app.trente.ui.screens.ExportMonthSelectionScreen
import app.trente.ui.screens.ExportSelectionState
import app.trente.ui.screens.FAQScreen
import app.trente.ui.screens.HomeScreen
import app.trente.ui.screens.MonthDetailsScreen
import app.trente.ui.screens.MonthScreen
import app.trente.ui.screens.NewMonthScreen
import app.trente.ui.screens.NewTransactionScreen
import app.trente.ui.screens.NotificationSettingsScreen
import app.trente.ui.screens.OnboardingScreen
import app.trente.ui.screens.RecurringRuleDetailsScreen
import app.trente.ui.screens.RecurringTransactionsListScreen
import app.trente.ui.screens.SettingsScreen
import app.trente.ui.screens.TransactionExportScreen
import app.trente.ui.screens.TransactionGroupDetailsScreen
import app.trente.ui.screens.TransactionListScreen
import app.trente.ui.screens.TrentePlusScreen
import java.util.UUID

object Routes {
    const val HOME = "home"
    const val RECURRING = "recurring"
    const val NEW_MONTH = "newMonth"
    const val SETTINGS = "settings"
    const val NOTIFICATIONS = "settings/notifications"
    const val EXPORT = "settings/export"
    const val EXPORT_MONTHS = "settings/export/months"
    const val FAQ = "settings/faq"
    const val ABOUT = "settings/about"
    const val CREDITS = "settings/credits"
    const val TRENTE_PLUS = "trentePlus"

    fun month(id: UUID) = "month/$id"
    fun monthDetails(id: UUID) = "month/$id/details"
    fun transactions(monthId: UUID, recurring: Boolean) = "month/$monthId/transactions?recurring=$recurring"
    fun newTransaction(monthId: UUID) = "newTransaction/$monthId"
    fun transaction(groupId: UUID, edit: Boolean) = "transaction/$groupId?edit=$edit"
    fun rule(ruleId: UUID) = "rule/$ruleId"
}

/** Routes to the onboarding or the app, and follows deep links, like the iOS `RootView` + `AppNavigationView`. */
@Composable
fun AppRoot(pendingDeepLink: DeepLink?, onDeepLinkHandled: () -> Unit) {
    val container = LocalAppContainer.current
    val store = rememberStore()
    val version = dataVersion()
    var hasCompletedOnboarding by remember { mutableStateOf(container.preferences.getBoolean(OnboardingGate.COMPLETED_KEY) ?: false) }
    var isReplayingOnboarding by remember { mutableStateOf(false) }

    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        if (store == null) {
            Box(Modifier.fillMaxSize())
            return@Surface
        }
        val showsOnboarding = remember(version, hasCompletedOnboarding, isReplayingOnboarding) {
            OnboardingGate.shouldShow(hasCompletedOnboarding, store.months.size, isReplayingOnboarding)
        }
        if (showsOnboarding) {
            OnboardingScreen(
                isFirstLaunch = !isReplayingOnboarding,
                onFinish = {
                    container.preferences.putBoolean(OnboardingGate.COMPLETED_KEY, true)
                    hasCompletedOnboarding = true
                    isReplayingOnboarding = false
                }
            )
            return@Surface
        }

        val navController = rememberNavController()
        val exportState = remember { ExportSelectionState() }

        LaunchedEffect(Unit) {
            MonthService.latestMonth(store)?.let { navController.navigate(Routes.month(it.id)) }
        }

        LaunchedEffect(pendingDeepLink) {
            val link = pendingDeepLink ?: return@LaunchedEffect
            val destination = link.destination(store.months.sortedByDescending { it.startDate })
            if (destination != null) {
                navController.navigate(Routes.month(destination.month.id)) { popUpTo(Routes.HOME) }
                if (destination.opensNewTransaction) navController.navigate(Routes.newTransaction(destination.month.id))
            }
            onDeepLinkHandled()
        }

        CompositionLocalProvider(LocalShowPaywall provides { navController.navigate(Routes.TRENTE_PLUS) }) {
            TrenteNavHost(navController, exportState, onReplayOnboarding = { isReplayingOnboarding = true })
        }
    }
}

@Composable
private fun TrenteNavHost(navController: NavHostController, exportState: ExportSelectionState, onReplayOnboarding: () -> Unit) {
    fun uuid(entry: androidx.navigation.NavBackStackEntry, key: String): UUID = UUID.fromString(entry.arguments?.getString(key))

    NavHost(navController = navController, startDestination = Routes.HOME) {
        composable(Routes.HOME) {
            HomeScreen(
                onOpenMonth = { navController.navigate(Routes.month(it)) { popUpTo(Routes.HOME) } },
                onOpenRecurring = { navController.navigate(Routes.RECURRING) { popUpTo(Routes.HOME) } },
                onNewMonth = { navController.navigate(Routes.NEW_MONTH) },
                onOpenSettings = { navController.navigate(Routes.SETTINGS) }
            )
        }
        composable("month/{monthId}", arguments = listOf(navArgument("monthId") { type = NavType.StringType })) { entry ->
            val monthId = uuid(entry, "monthId")
            MonthScreen(
                monthId = monthId,
                onBack = { navController.popBackStack() },
                onEditMonth = { navController.navigate(Routes.monthDetails(monthId)) },
                onOpenTransactions = { recurring -> navController.navigate(Routes.transactions(monthId, recurring)) },
                onAddTransaction = { navController.navigate(Routes.newTransaction(monthId)) },
                onOpenTransaction = { id, edit -> navController.navigate(Routes.transaction(id, edit)) },
                onOpenRule = { navController.navigate(Routes.rule(it)) }
            )
        }
        composable("month/{monthId}/details", arguments = listOf(navArgument("monthId") { type = NavType.StringType })) { entry ->
            MonthDetailsScreen(
                monthId = uuid(entry, "monthId"),
                onBack = { navController.popBackStack() },
                onDeleted = { navController.popBackStack(Routes.HOME, inclusive = false) }
            )
        }
        composable(
            "month/{monthId}/transactions?recurring={recurring}",
            arguments = listOf(
                navArgument("monthId") { type = NavType.StringType },
                navArgument("recurring") { type = NavType.BoolType; defaultValue = false }
            )
        ) { entry ->
            TransactionListScreen(
                monthId = uuid(entry, "monthId"),
                showRecurring = entry.arguments?.getBoolean("recurring") ?: false,
                onBack = { navController.popBackStack() },
                onOpenTransaction = { id, edit -> navController.navigate(Routes.transaction(id, edit)) },
                onOpenRule = { navController.navigate(Routes.rule(it)) }
            )
        }
        composable(Routes.RECURRING) {
            RecurringTransactionsListScreen(
                onBack = { navController.popBackStack() },
                onOpenRule = { navController.navigate(Routes.rule(it)) }
            )
        }
        composable("newTransaction/{monthId}", arguments = listOf(navArgument("monthId") { type = NavType.StringType })) { entry ->
            NewTransactionScreen(monthId = uuid(entry, "monthId"), onClose = { navController.popBackStack() })
        }
        composable(Routes.NEW_MONTH) {
            NewMonthScreen(
                onClose = { navController.popBackStack() },
                onCreated = { navController.navigate(Routes.month(it)) { popUpTo(Routes.HOME) } }
            )
        }
        composable(
            "transaction/{groupId}?edit={edit}",
            arguments = listOf(
                navArgument("groupId") { type = NavType.StringType },
                navArgument("edit") { type = NavType.BoolType; defaultValue = false }
            )
        ) { entry ->
            TransactionGroupDetailsScreen(
                groupId = uuid(entry, "groupId"),
                startInEditMode = entry.arguments?.getBoolean("edit") ?: false,
                onClose = { navController.popBackStack() }
            )
        }
        composable("rule/{ruleId}", arguments = listOf(navArgument("ruleId") { type = NavType.StringType })) { entry ->
            RecurringRuleDetailsScreen(ruleId = uuid(entry, "ruleId"), onClose = { navController.popBackStack() })
        }
        composable(Routes.SETTINGS) {
            SettingsScreen(
                onClose = { navController.popBackStack() },
                onOpen = { navController.navigate(it) },
                onReplayOnboarding = onReplayOnboarding
            )
        }
        composable(Routes.NOTIFICATIONS) { NotificationSettingsScreen(onBack = { navController.popBackStack() }) }
        composable(Routes.EXPORT) {
            TransactionExportScreen(state = exportState, onBack = { navController.popBackStack() }, onSelectMonths = { navController.navigate(Routes.EXPORT_MONTHS) })
        }
        composable(Routes.EXPORT_MONTHS) { ExportMonthSelectionScreen(state = exportState, onBack = { navController.popBackStack() }) }
        composable(Routes.FAQ) { FAQScreen(onBack = { navController.popBackStack() }) }
        composable(Routes.ABOUT) { AboutDeveloperScreen(onBack = { navController.popBackStack() }) }
        composable(Routes.CREDITS) { CreditsScreen(onBack = { navController.popBackStack() }) }
        composable(Routes.TRENTE_PLUS) { TrentePlusScreen(onClose = { navController.popBackStack() }) }
    }
}
