package app.trente.ui.components

import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TrenteCalendar
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import java.time.format.TextStyle
import java.util.Locale

/** A transaction: a summary row for a split income, an entry row otherwise, like `TransactionGroupRowContent`. */
@Composable
fun TransactionGroupRowContent(group: TransactionGroup, modifier: Modifier = Modifier, expanded: Boolean = false) {
    val currencyCode = group.currency.isoCode
    when {
        group.entries.size > 1 -> Column(modifier) {
            SummaryRow(title = group.title, amountText = MoneyFormat.amount(group.totalAmount, currencyCode), expanded = expanded)
            if (expanded) {
                group.entries.forEach { entry ->
                    EntryRowContent(title = null, category = entry.category, amountText = MoneyFormat.amount(entry.amount, currencyCode), modifier = Modifier.padding(start = 24.dp, top = 6.dp))
                }
            }
        }
        group.entries.size == 1 -> EntryRowContent(
            title = group.title,
            category = group.entries.first().category,
            amountText = MoneyFormat.amount(group.totalAmount, currencyCode),
            modifier = modifier
        )
    }
}

@Composable
private fun SummaryRow(title: String, amountText: String, expanded: Boolean) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        CategoryDot(TrenteColors.red)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = TrenteType.headline, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(localized("Income"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
        }
        Text(amountText, style = TrenteType.title3)
        Icon(if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore, contentDescription = null, tint = TrenteColors.secondaryText)
    }
}

@Composable
fun EntryRowContent(title: String?, category: BudgetCategory, amountText: String, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        CategoryDot(category.color)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            if (title != null) {
                Text(title, style = TrenteType.headline, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Text(category.displayName, style = TrenteType.subheadline, color = TrenteColors.secondaryText)
        }
        Text(
            amountText,
            style = if (title != null) TrenteType.title3 else TrenteType.subheadline,
            color = if (title != null) MaterialTheme.colorScheme.onSurface else TrenteColors.secondaryText
        )
    }
}

/** A tappable transaction row with Edit and Delete in a long-press menu, like `TransactionGroupRowView`. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TransactionGroupRow(
    group: TransactionGroup,
    onOpen: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isMenuOpen by remember { mutableStateOf(false) }
    var isConfirmingDelete by remember { mutableStateOf(false) }
    var isExpanded by remember { mutableStateOf(false) }
    Box(modifier) {
        TransactionGroupRowContent(
            group = group,
            expanded = isExpanded,
            modifier = Modifier
                .fillMaxWidth()
                .combinedClickable(
                    onClick = { if (group.entries.size > 1) isExpanded = !isExpanded else onOpen() },
                    onLongClick = { isMenuOpen = true }
                )
                .padding(vertical = 10.dp)
        )
        DropdownMenu(expanded = isMenuOpen, onDismissRequest = { isMenuOpen = false }) {
            DropdownMenuItem(text = { Text(localized("Edit")) }, leadingIcon = { Icon(Icons.Default.Edit, null) }, onClick = { isMenuOpen = false; onEdit() })
            DropdownMenuItem(
                text = { Text(localized("Delete"), color = MaterialTheme.colorScheme.error) },
                leadingIcon = { Icon(Icons.Default.Delete, null, tint = MaterialTheme.colorScheme.error) },
                onClick = { isMenuOpen = false; isConfirmingDelete = true }
            )
        }
    }
    if (isConfirmingDelete) {
        DeleteConfirmationDialog(onDismiss = { isConfirmingDelete = false }, onDelete = { isConfirmingDelete = false; onDelete() })
    }
}

/** A pending occurrence: date badge, title, "category · frequency", amount; like `RecurringTransactionRowView`. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun RecurringOccurrenceRow(
    occurrence: RecurringTransactionOccurrence,
    onOpen: () -> Unit,
    onConfirm: () -> Unit,
    onSkip: () -> Unit,
    modifier: Modifier = Modifier,
    calendar: TrenteCalendar = TrenteCalendar.current
) {
    var isMenuOpen by remember { mutableStateOf(false) }
    var isConfirming by remember { mutableStateOf(false) }
    var isSkipping by remember { mutableStateOf(false) }
    val isOverdue = occurrence.isOverdue(calendar = calendar)
    val day = calendar.localDate(occurrence.date)
    val orange = TrenteColors.orange
    Box(modifier) {
        Row(
            Modifier
                .fillMaxWidth()
                .combinedClickable(onClick = onOpen, onLongClick = { isMenuOpen = true })
                .padding(vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Column(Modifier.width(40.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("${day.dayOfMonth}", style = TrenteType.title3, color = if (isOverdue) orange else MaterialTheme.colorScheme.onSurface)
                Text(
                    day.month.getDisplayName(TextStyle.SHORT, Locale.getDefault()).uppercase(),
                    style = TrenteType.caption2,
                    color = if (isOverdue) orange else TrenteColors.secondaryText
                )
            }
            Column(Modifier.weight(1f)) {
                Text(occurrence.rule.title, style = TrenteType.headline, maxLines = 1, overflow = TextOverflow.Ellipsis)
                if (isOverdue) {
                    Row {
                        Text(localized("Overdue"), style = TrenteType.subheadline, color = orange)
                        Text(" · ${occurrence.categoryName}", style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                    }
                } else {
                    Text(localized("%@ · %@", occurrence.categoryName, occurrence.rule.frequency.displayName), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                }
            }
            Text(MoneyFormat.amountCents(occurrence.amountCents, occurrence.month.currency.isoCode), style = TrenteType.title2.copy(fontWeight = FontWeight.SemiBold))
        }
        DropdownMenu(expanded = isMenuOpen, onDismissRequest = { isMenuOpen = false }) {
            DropdownMenuItem(
                text = { Text(if (occurrence.isIncome) localized("Received") else localized("Paid")) },
                leadingIcon = { Icon(Icons.Default.CheckCircle, null, tint = TrenteColors.green) },
                onClick = { isMenuOpen = false; isConfirming = true }
            )
            DropdownMenuItem(text = { Text(localized("Skip")) }, leadingIcon = { Icon(Icons.Default.SkipNext, null) }, onClick = { isMenuOpen = false; isSkipping = true })
        }
    }
    if (isConfirming) {
        ConfirmOccurrenceDialog(occurrence = occurrence, onDismiss = { isConfirming = false }, onConfirm = { isConfirming = false; onConfirm() })
    }
    if (isSkipping) {
        SkipOccurrenceDialog(occurrence = occurrence, onDismiss = { isSkipping = false }, onSkip = { isSkipping = false; onSkip() }, calendar = calendar)
    }
}

@Composable
fun ConfirmOccurrenceDialog(occurrence: RecurringTransactionOccurrence, onDismiss: () -> Unit, onConfirm: () -> Unit) {
    val title = occurrence.rule.title
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (occurrence.isIncome) localized("Mark %@ as received?", title) else localized("Mark %@ as paid?", title)) },
        text = { Text(localized("It's added to this month's transactions.")) },
        confirmButton = {
            androidx.compose.material3.TextButton(onClick = onConfirm) {
                Text(if (occurrence.isIncome) localized("Mark as Received") else localized("Mark as Paid"))
            }
        },
        dismissButton = { androidx.compose.material3.TextButton(onClick = onDismiss) { Text(localized("Cancel")) } }
    )
}

/** The skip confirmation, worded by frequency, like `.skipOccurrenceConfirmation`. */
@Composable
fun SkipOccurrenceDialog(
    occurrence: RecurringTransactionOccurrence,
    onDismiss: () -> Unit,
    onSkip: () -> Unit,
    calendar: TrenteCalendar = TrenteCalendar.current
) {
    val title = occurrence.rule.title
    val day = calendar.localDate(occurrence.date)
    val dayName = app.trente.core.support.DateText.dayMonthWide(day)
    val monthName = app.trente.core.support.DateText.monthWide(day)
    val yearName = day.year.toString()
    val (dialogTitle, button, message) = when (occurrence.rule.frequency) {
        app.trente.core.model.RecurrenceFrequency.WEEKLY -> Triple(
            localized("Skip “%@” on %@?", title, dayName),
            localized("Skip on %@", dayName),
            localized("It won't be added that week. Next weeks aren't affected. You can't undo this.")
        )
        app.trente.core.model.RecurrenceFrequency.MONTHLY -> Triple(
            localized("Skip “%@” for %@?", title, monthName),
            localized("Skip for %@", monthName),
            localized("It won't be added to %@. Next months aren't affected. You can't undo this.", monthName)
        )
        app.trente.core.model.RecurrenceFrequency.YEARLY -> Triple(
            localized("Skip “%@” in %@?", title, yearName),
            localized("Skip in %@", yearName),
            localized("It won't be added in %@. Next years aren't affected. You can't undo this.", yearName)
        )
    }
    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(dialogTitle) },
        text = { Text(message) },
        confirmButton = {
            androidx.compose.material3.TextButton(onClick = onSkip, colors = androidx.compose.material3.ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                Text(button)
            }
        },
        dismissButton = { androidx.compose.material3.TextButton(onClick = onDismiss) { Text(localized("Cancel")) } }
    )
}

@Composable
fun RowDivider() {
    HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
}
