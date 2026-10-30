package app.trente.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.ui.draw.alpha
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.presentation.DisplayableTransaction
import app.trente.core.presentation.SortOption
import app.trente.core.presentation.TransactionListFilter
import app.trente.core.services.RecurringTransactionService
import app.trente.core.services.TransactionService
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.TransactionActions
import app.trente.ui.components.DateField
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.RecurringOccurrenceRow
import app.trente.ui.components.RowDivider
import app.trente.ui.components.TransactionGroupRow
import app.trente.ui.components.TrenteListBackground
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.dataVersion
import app.trente.ui.rememberStore
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import java.util.UUID

/** Every transaction, or every expected occurrence, of a month with search, sort and filters, like `TransactionListView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionListScreen(
    monthId: UUID,
    showRecurring: Boolean,
    onBack: () -> Unit,
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
    val filter = remember { TransactionListFilter(month) }
    var filterVersion by remember { mutableIntStateOf(0) }
    fun updateFilter(block: TransactionListFilter.() -> Unit) {
        filter.block()
        filterVersion += 1
    }
    val items = remember(version, filterVersion) {
        val all = if (showRecurring) {
            RecurringTransactionService.pendingOccurrences(store.rules, month).map { DisplayableTransaction.Recurring(it) }
        } else {
            month.transactionGroups.sortedBy { it.addedDate }.map { DisplayableTransaction.Group(it) }
        }
        filter.apply(all)
    }
    val isFilterActive = remember(filterVersion) { filter.isActive(month) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val actions = remember(store) { TransactionActions(store) { errorMessage = it } }
    var presentedOccurrence by remember { mutableStateOf<RecurringTransactionOccurrence?>(null) }
    var isFiltering by remember { mutableStateOf(false) }
    var isSortOpen by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TrenteTopBar(title = localized("Transactions"), onBack = onBack) {
                Box {
                    IconButton(onClick = { isSortOpen = true }) { Icon(Icons.Default.SwapVert, contentDescription = localized("Sort")) }
                    SortMenu(expanded = isSortOpen, sort = filter.sort, onDismiss = { isSortOpen = false }, onSelect = { updateFilter { sort = it } })
                }
                IconButton(onClick = { isFiltering = true }) {
                    Icon(Icons.Default.FilterList, contentDescription = localized("Filter"), tint = if (isFilterActive) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface)
                }
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            OutlinedTextField(
                value = filter.searchText,
                onValueChange = { text -> updateFilter { searchText = text } },
                placeholder = { Text(localized("Search by title, amount, date, category…")) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                trailingIcon = {
                    if (filter.searchText.isNotEmpty()) {
                        IconButton(onClick = { updateFilter { searchText = "" } }) { Icon(Icons.Default.Close, contentDescription = null) }
                    }
                },
                singleLine = true,
                shape = androidx.compose.foundation.shape.CircleShape,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
            )
            if (items.isEmpty() && (isFilterActive || filter.searchText.isNotEmpty())) {
                Column(Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    Icon(Icons.Default.FilterList, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.padding(8.dp))
                    Text(localized("No Matching Transactions"), style = TrenteType.title2)
                    Text(localized("No transactions match these filters."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                    TextButton(onClick = { updateFilter { reset(month) } }) { Text(localized("Reset Filters")) }
                }
                return@Column
            }
            LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                item {
                    TrenteListBackground {
                        items.forEachIndexed { index, item ->
                            Box(Modifier.padding(horizontal = 16.dp)) {
                                when (item) {
                                    is DisplayableTransaction.Group -> TransactionGroupRow(
                                        group = item.group,
                                        onOpen = { onOpenTransaction(item.group.id, false) },
                                        onEdit = { onOpenTransaction(item.group.id, true) },
                                        onDelete = { actions.delete(item.group) }
                                    )
                                    is DisplayableTransaction.Recurring -> RecurringOccurrenceRow(
                                        occurrence = item.occurrence,
                                        onOpen = { presentedOccurrence = item.occurrence },
                                        onConfirm = { actions.confirm(item.occurrence) },
                                        onSkip = { actions.skip(item.occurrence) }
                                    )
                                }
                            }
                            if (index < items.size - 1) RowDivider()
                        }
                        if (items.isEmpty()) {
                            Text(
                                if (showRecurring) localized("Nothing else expected this month.") else localized("Add your first transaction for this month by tapping 'Add Transaction'."),
                                style = TrenteType.subheadline,
                                color = TrenteColors.secondaryText,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                }
                item {
                    TrenteListBackground {
                        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(localized("Total"), style = TrenteType.headline)
                                Text(localized("Sum of displayed transactions"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                            }
                            Text(MoneyFormat.amountCents(filter.totalCents(items), month.currency.isoCode), style = TrenteType.title)
                        }
                    }
                }
            }
        }
    }

    if (isFiltering) {
        val bounds = remember { TransactionService.fetchTransactionDateBounds(store) }
        ModalBottomSheet(onDismissRequest = { isFiltering = false }, containerColor = MaterialTheme.colorScheme.background) {
            Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    TextButton(onClick = { updateFilter { reset(month) } }, enabled = isFilterActive || filter.searchText.isNotEmpty()) { Text(localized("Reset")) }
                    Spacer(Modifier.weight(1f))
                    Text(localized("Filter"), style = TrenteType.headline)
                    Spacer(Modifier.weight(1f))
                    TextButton(onClick = { isFiltering = false }) { Text(localized("Done")) }
                }
                Text(localized("Dates"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                TrenteListBackground {
                    Column(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                        DateField(label = localized("From"), date = filter.firstDay, onDateChange = { date -> updateFilter { firstDay = date } }, minDate = bounds.start, maxDate = bounds.endInclusive)
                        DateField(label = localized("To"), date = filter.lastDay, onDateChange = { date -> updateFilter { lastDay = date } }, minDate = bounds.start, maxDate = bounds.endInclusive)
                    }
                }
                Text(localized("Categories"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                TrenteListBackground {
                    BudgetCategory.entries.forEach { category ->
                        val isSelected = category in filter.categories
                        Row(
                            Modifier.fillMaxWidth().clickable {
                                updateFilter { categories = if (isSelected) categories - category else categories + category }
                            }.padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(if (isSelected) Icons.Default.CheckCircle else Icons.Outlined.Circle, contentDescription = null, tint = category.color)
                            Spacer(Modifier.width(12.dp))
                            Text(category.displayName, style = TrenteType.body)
                        }
                    }
                }
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

/** "Sort by" Date / Amount / Title; tapping the active one flips its direction, like `SortPickerView`. */
@Composable
private fun SortMenu(expanded: Boolean, sort: SortOption, onDismiss: () -> Unit, onSelect: (SortOption) -> Unit) {
    data class Choice(val title: String, val ascending: SortOption, val descending: SortOption)
    val choices = listOf(
        Choice(localized("Date"), SortOption.DATE_ASC, SortOption.DATE_DESC),
        Choice(localized("Amount"), SortOption.AMOUNT_ASC, SortOption.AMOUNT_DESC),
        Choice(localized("Title"), SortOption.TITLE_ASC, SortOption.TITLE_DESC)
    )
    DropdownMenu(expanded = expanded, onDismissRequest = onDismiss) {
        Text(localized("Sort by"), style = TrenteType.headline, modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
        choices.forEach { choice ->
            val isActive = sort == choice.ascending || sort == choice.descending
            DropdownMenuItem(
                text = { Text(choice.title) },
                trailingIcon = {
                    if (isActive) Icon(if (sort == choice.ascending) Icons.Default.ArrowUpward else Icons.Default.ArrowDownward, contentDescription = null)
                },
                onClick = {
                    onSelect(if (sort == choice.ascending) choice.descending else choice.ascending)
                    onDismiss()
                }
            )
        }
    }
}

/** Every recurring rule, active then ended, like `RecurringTransactionsListView`. */
@Composable
fun RecurringTransactionsListScreen(onBack: () -> Unit, onOpenRule: (UUID) -> Unit) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val rules = remember(version) { store.rules.sortedBy { it.title } }
    val currencyCode = remember(version) { store.months.maxByOrNull { it.startDate }?.currency?.isoCode ?: app.trente.core.model.Currency.fallback.isoCode }
    val active = rules.filter { !it.hasEnded() }
    val ended = rules.filter { it.hasEnded() }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val actions = remember(store) { TransactionActions(store) { errorMessage = it } }
    var ruleToDelete by remember { mutableStateOf<app.trente.core.model.RecurringTransactionRule?>(null) }

    Scaffold(topBar = { TrenteTopBar(title = localized("Recurring Transactions"), onBack = onBack) }) { padding ->
        if (rules.isEmpty()) {
            Column(Modifier.fillMaxSize().padding(padding).padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Text(localized("No Recurring Transactions"), style = TrenteType.title2)
                Text(localized("Turn on \"Recurring transaction\" when you add a transaction."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            }
            return@Scaffold
        }
        LazyColumn(contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = padding.calculateTopPadding() + 8.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            listOf(localized("Active") to active, localized("Ended") to ended).forEach { (title, section) ->
                if (section.isEmpty()) return@forEach
                item { Text(title.uppercase(), style = TrenteType.subheadline, color = TrenteColors.secondaryText, modifier = Modifier.padding(horizontal = 16.dp)) }
                item {
                    TrenteListBackground {
                        section.forEachIndexed { index, rule ->
                            RuleSummaryRow(rule = rule, currencyCode = currencyCode, onOpen = { onOpenRule(rule.id) }, onDelete = { ruleToDelete = rule })
                            if (index < section.size - 1) RowDivider()
                        }
                    }
                }
            }
        }
    }
    ruleToDelete?.let { rule ->
        app.trente.ui.components.DeleteConfirmationDialog(onDismiss = { ruleToDelete = null }, onDelete = { actions.delete(rule); ruleToDelete = null })
    }
    ErrorAlert(message = errorMessage, onDismiss = { errorMessage = null })
}

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
private fun RuleSummaryRow(rule: app.trente.core.model.RecurringTransactionRule, currencyCode: String, onOpen: () -> Unit, onDelete: () -> Unit) {
    var isMenuOpen by remember { mutableStateOf(false) }
    val isEnded = rule.hasEnded()
    val schedule = if (isEnded) {
        localized("Ended on %@", app.trente.core.support.DateText.mediumDate(app.trente.core.model.TrenteCalendar.current.localDate(rule.endDate!!)))
    } else {
        rule.frequencyDescription()
    }
    Box {
        Row(
            Modifier
                .fillMaxWidth()
                .combinedClickable(onClick = onOpen, onLongClick = { isMenuOpen = true })
                .padding(16.dp)
                .alpha(if (isEnded) 0.5f else 1f),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(rule.title, style = TrenteType.headline)
                Text(schedule, style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            }
            Text(MoneyFormat.amountCents(rule.amountCents, currencyCode), style = TrenteType.title3)
        }
        DropdownMenu(expanded = isMenuOpen, onDismissRequest = { isMenuOpen = false }) {
            DropdownMenuItem(text = { Text(localized("Delete"), color = MaterialTheme.colorScheme.error) }, onClick = { isMenuOpen = false; onDelete() })
        }
    }
}
