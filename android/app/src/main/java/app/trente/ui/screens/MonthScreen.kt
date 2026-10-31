package app.trente.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.presentation.BudgetRings
import app.trente.core.presentation.DailySpending
import app.trente.core.services.RecurringTransactionService
import app.trente.core.support.localized
import app.trente.ui.TransactionActions
import app.trente.ui.components.CardCarousel
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.dataVersion
import app.trente.ui.rememberStore
import java.util.UUID

/** The month dashboard: the three cards, the latest transactions and what's expected, like `MonthView`. */
@Composable
fun MonthScreen(
    monthId: UUID,
    onBack: () -> Unit,
    onEditMonth: () -> Unit,
    onOpenTransactions: (recurring: Boolean) -> Unit,
    onAddTransaction: () -> Unit,
    onOpenTransaction: (UUID, edit: Boolean) -> Unit,
    onOpenRule: (UUID) -> Unit
) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val month = remember(version, monthId) { store.month(monthId) }
    if (month == null) {
        LaunchedEffect(Unit) { onBack() }
        return
    }
    val rings = remember(version) { BudgetRings(month) }
    val gauges = remember(version) { budgetGaugeScopes.map { it to month.figures(it) } }
    val latest = remember(version) { month.latestTransactions.take(3) }
    val spending = remember(version) { DailySpending(month) }
    val upcoming = remember(version) { RecurringTransactionService.pendingOccurrences(store.rules, month) }
    val hasRules = remember(version) { store.rules.isNotEmpty() }
    val hasAnyTransaction = remember(version) { store.transactionGroups.isNotEmpty() }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val actions = remember(store) { TransactionActions(store) { errorMessage = it } }
    var presentedOccurrence by remember { mutableStateOf<RecurringTransactionOccurrence?>(null) }
    val pagerState = rememberPagerState { 3 }

    Scaffold(
        topBar = {
            TrenteTopBar(title = month.name, onBack = onBack) {
                IconButton(onClick = onEditMonth) { Icon(Icons.Default.Edit, contentDescription = localized("Edit Month")) }
            }
        },
        bottomBar = {
            Box(
                Modifier
                    .fillMaxWidth()
                    .background(Brush.verticalGradient(listOf(Color.Transparent, MaterialTheme.colorScheme.background)))
                    .navigationBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                TrentePrimaryButton(text = localized("Add Transaction"), icon = Icons.Default.Add, onClick = onAddTransaction)
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = padding.calculateTopPadding() + 8.dp, bottom = padding.calculateBottomPadding() + 16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            item {
                CardCarousel(state = pagerState) { page ->
                    when (page) {
                        0 -> BudgetRingsCard(rings = rings)
                        1 -> BudgetGaugesCard(gauges = gauges, currencyCode = month.currency.isoCode)
                        else -> DailySpendingCard(spending = spending, currencyCode = month.currency.isoCode)
                    }
                }
            }
            item {
                LatestTransactionsCard(
                    latest = latest,
                    hasAnyTransaction = hasAnyTransaction,
                    onSeeAll = { onOpenTransactions(false) },
                    onOpen = { onOpenTransaction(it.id, false) },
                    onEdit = { onOpenTransaction(it.id, true) },
                    onDelete = { actions.delete(it) },
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }
            item {
                UpcomingRecurringCard(
                    occurrences = upcoming,
                    count = 3,
                    hasRules = hasRules,
                    onSeeAll = { onOpenTransactions(true) },
                    onOpen = { presentedOccurrence = it },
                    onConfirm = { actions.confirm(it) },
                    onSkip = { actions.skip(it) },
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }
        }
    }

    presentedOccurrence?.let { occurrence ->
        RecurringOccurrenceSheet(
            occurrence = occurrence,
            onDismiss = { presentedOccurrence = null },
            onConfirm = { actions.confirm(occurrence); presentedOccurrence = null },
            onSkip = { actions.skip(occurrence); presentedOccurrence = null },
            onOpenRule = { presentedOccurrence = null; onOpenRule(occurrence.rule.id) }
        )
    }
    ErrorAlert(message = errorMessage, onDismiss = { errorMessage = null })
}
