package app.trente.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.EventRepeat
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.LocalAppContainer
import app.trente.ui.components.TrenteListBackground
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.dataVersion
import app.trente.ui.rememberStore
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.Dimens
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import java.util.UUID

/** "All Months": the current month, the recurring transactions and the archived months, like `SidebarView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onOpenMonth: (UUID) -> Unit,
    onOpenRecurring: () -> Unit,
    onNewMonth: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val months = remember(version) { store.months.sortedByDescending { it.startDate } }
    val activeRules = remember(version) { store.rules.count { !it.hasEnded() } }
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior(rememberTopAppBarState())

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            LargeTopAppBar(
                title = { Text(localized("All Months")) },
                actions = {
                    IconButton(onClick = onOpenSettings) { Icon(Icons.Default.Settings, contentDescription = localized("Settings")) }
                },
                scrollBehavior = scrollBehavior,
                colors = TopAppBarDefaults.largeTopAppBarColors(containerColor = MaterialTheme.colorScheme.surface, scrolledContainerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = padding.calculateBottomPadding() + 32.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            months.firstOrNull()?.let { current ->
                item { SectionHeader(localized("CURRENT MONTH")) }
                item {
                    MonthSummaryCard(
                        name = current.name,
                        remaining = current.remainingAmount,
                        spent = current.spentAmount(app.trente.core.model.BudgetScope.All),
                        currencyCode = current.currency.isoCode,
                        isOverspent = current.overSpent,
                        onSelect = { onOpenMonth(current.id) }
                    )
                }
            }
            item {
                TrenteSecondaryButton(text = localized("Start a New Month"), icon = Icons.Default.History, onClick = onNewMonth, modifier = Modifier.padding(vertical = 8.dp))
            }
            if (months.isNotEmpty()) {
                item { SectionHeader(localized("RECURRING")) }
                item {
                    TrenteListBackground {
                        Row(
                            Modifier.fillMaxWidth().clickable(onClick = onOpenRecurring).padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Default.EventRepeat, contentDescription = null)
                            Spacer(Modifier.width(12.dp))
                            Text(localized("Recurring Transactions"), style = TrenteType.body, modifier = Modifier.weight(1f))
                            Text(pluralized("%lld active", activeRules), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = TrenteColors.secondaryText)
                        }
                    }
                }
            }
            if (months.size > 1) {
                item { SectionHeader(localized("ARCHIVED MONTHS")) }
                item {
                    TrenteListBackground {
                        months.drop(1).forEachIndexed { index, month ->
                            ArchivedMonthRow(name = month.name, isOverspent = month.overSpent, onSelect = { onOpenMonth(month.id) })
                            if (index < months.size - 2) HorizontalDivider(Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text, style = TrenteType.subheadline, color = TrenteColors.secondaryText, modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp))
}

@Composable
private fun ArchivedMonthRow(name: String, isOverspent: Boolean, onSelect: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onSelect).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(name, style = TrenteType.body, modifier = Modifier.weight(1f))
        Text(
            if (isOverspent) localized("Over Budget") else localized("Under Budget"),
            style = TrenteType.subheadline,
            color = TrenteColors.secondaryText
        )
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = TrenteColors.secondaryText)
    }
}

/** The gradient card of the current month: name, status, remaining and spent, like `MonthSummaryCard`. */
@Composable
fun MonthSummaryCard(
    name: String,
    remaining: Double,
    spent: Double,
    currencyCode: String,
    isOverspent: Boolean,
    modifier: Modifier = Modifier,
    isSelected: Boolean = false,
    onSelect: (() -> Unit)? = null
) {
    val red = TrenteColors.red
    val green = TrenteColors.green
    val isDark = isSystemInDarkTheme()
    val overlay = if (isDark) Color.Black else Color.White
    Box(
        modifier
            .fillMaxWidth()
            .clip(CardShape)
            .background(Brush.linearGradient(listOf((if (isOverspent) red else green).copy(alpha = 0.6f), red.copy(alpha = 0.6f))))
            .background(Brush.verticalGradient(listOf(overlay.copy(alpha = 0.85f), overlay.copy(alpha = 0.4f))))
            .let { if (onSelect != null) it.clickable(onClick = onSelect) else it }
    ) {
        Surface(
            color = Color.Transparent,
            shape = CardShape,
            border = BorderStroke(Dimens.cardBorder, MaterialTheme.colorScheme.onSurface.copy(alpha = if (isSelected) 0.5f else 0.2f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(name, style = TrenteType.headline, modifier = Modifier.weight(1f))
                    Text(if (isOverspent) localized("Over Budget") else localized("Under Budget"), style = TrenteType.subheadline)
                }
                HorizontalDivider(Modifier.padding(vertical = 10.dp), color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f))
                Row {
                    Column(Modifier.weight(1f)) {
                        Text(localized("Remaining"), style = TrenteType.subheadline)
                        Text(MoneyFormat.amount(remaining, currencyCode), style = TrenteType.title, color = if (isOverspent) red else green)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(localized("Spent"), style = TrenteType.subheadline)
                        Text(MoneyFormat.amount(if (spent == 0.0) 0.0 else -spent, currencyCode), style = TrenteType.title, color = red)
                    }
                }
            }
        }
    }
}
