package app.trente.ui

import androidx.activity.compose.BackHandler
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
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.lifecycle.Lifecycle
import androidx.navigation.NavBackStackEntry
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

    Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        if (store == null) {
            Box(Modifier.fillMaxSize())
            return@Surface
        }
        var isShowingOnboarding by rememberSaveable {
            val hasCompleted = container.preferences.getBoolean(OnboardingGate.COMPLETED_KEY) ?: false
            mutableStateOf(OnboardingGate.shouldShow(hasCompleted, store.months.size, isForced = false))
        }
        var isFirstLaunch by rememberSaveable { mutableStateOf(isShowingOnboarding) }
        if (isShowingOnboarding) {
            LaunchedEffect(pendingDeepLink) { if (pendingDeepLink != null) onDeepLinkHandled() }
            OnboardingScreen(
                isFirstLaunch = isFirstLaunch,
                onFinish = {
                    container.preferences.putBoolean(OnboardingGate.COMPLETED_KEY, true)
                    isShowingOnboarding = false
                }
            )
            return@Surface
        }

        val navController = rememberNavController()
        val exportState = remember { ExportSelectionState() }
        var hasOpenedLatestMonth by rememberSaveable { mutableStateOf(false) }

        LaunchedEffect(Unit) {
            if (hasOpenedLatestMonth) return@LaunchedEffect
            hasOpenedLatestMonth = true
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

        var isShowingPaywall by rememberSaveable { mutableStateOf(false) }
        CompositionLocalProvider(LocalShowPaywall provides { isShowingPaywall = true }) {
            Box(if (isShowingPaywall) Modifier.fillMaxSize().clearAndSetSemantics {} else Modifier.fillMaxSize()) {
                TrenteNavHost(
                    navController,
                    exportState,
                    onReplayOnboarding = {
                        isFirstLaunch = false
                        isShowingOnboarding = true
                    }
                )
            }
        }
        if (isShowingPaywall) {
            BackHandler { isShowingPaywall = false }
            TrentePlusScreen(onClose = { isShowingPaywall = false })
        }
    }
}

@Composable
private fun TrenteNavHost(navController: NavHostController, exportState: ExportSelectionState, onReplayOnboarding: () -> Unit) {
    fun uuid(entry: NavBackStackEntry, key: String): UUID = UUID.fromString(entry.arguments?.getString(key))

    fun popIfCurrent(entry: NavBackStackEntry) {
        if (entry.lifecycle.currentState == Lifecycle.State.RESUMED) navController.popBackStack()
    }

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
                onBack = { popIfCurrent(entry) },
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
                onBack = { popIfCurrent(entry) },
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
                onBack = { popIfCurrent(entry) },
                onOpenTransaction = { id, edit -> navController.navigate(Routes.transaction(id, edit)) },
                onOpenRule = { navController.navigate(Routes.rule(it)) }
            )
        }
        composable(Routes.RECURRING) { entry ->
            RecurringTransactionsListScreen(
                onBack = { popIfCurrent(entry) },
                onOpenRule = { navController.navigate(Routes.rule(it)) }
            )
        }
        composable("newTransaction/{monthId}", arguments = listOf(navArgument("monthId") { type = NavType.StringType })) { entry ->
            NewTransactionScreen(monthId = uuid(entry, "monthId"), onClose = { popIfCurrent(entry) })
        }
        composable(Routes.NEW_MONTH) { entry ->
            NewMonthScreen(
                onClose = { popIfCurrent(entry) },
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
                onClose = { popIfCurrent(entry) }
            )
        }
        composable("rule/{ruleId}", arguments = listOf(navArgument("ruleId") { type = NavType.StringType })) { entry ->
            RecurringRuleDetailsScreen(ruleId = uuid(entry, "ruleId"), onClose = { popIfCurrent(entry) })
        }
        composable(Routes.SETTINGS) { entry ->
            SettingsScreen(
                onClose = { popIfCurrent(entry) },
                onOpen = { navController.navigate(it) },
                onReplayOnboarding = onReplayOnboarding
            )
        }
        composable(Routes.NOTIFICATIONS) { entry -> NotificationSettingsScreen(onBack = { popIfCurrent(entry) }) }
        composable(Routes.EXPORT) { entry ->
            TransactionExportScreen(state = exportState, onBack = { popIfCurrent(entry) }, onSelectMonths = { navController.navigate(Routes.EXPORT_MONTHS) })
        }
        composable(Routes.EXPORT_MONTHS) { entry -> ExportMonthSelectionScreen(state = exportState, onBack = { popIfCurrent(entry) }) }
        composable(Routes.FAQ) { entry -> FAQScreen(onBack = { popIfCurrent(entry) }) }
        composable(Routes.ABOUT) { entry -> AboutDeveloperScreen(onBack = { popIfCurrent(entry) }) }
        composable(Routes.CREDITS) { entry -> CreditsScreen(onBack = { popIfCurrent(entry) }) }
    }
}
