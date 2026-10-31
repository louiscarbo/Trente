package app.trente.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetFigures
import app.trente.core.model.BudgetScope
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TrenteCalendar
import app.trente.core.presentation.BudgetRings
import app.trente.core.presentation.CategorySlice
import app.trente.core.presentation.DailySpend
import app.trente.core.presentation.DailySpending
import app.trente.core.support.DateText
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.components.BudgetGaugeView
import app.trente.ui.components.BudgetRingsView
import app.trente.ui.components.CategoryDot
import app.trente.ui.components.ProportionalBar
import app.trente.ui.components.RecurringOccurrenceRow
import app.trente.ui.components.RowDivider
import app.trente.ui.components.SkipOccurrenceDialog
import app.trente.ui.components.TransactionGroupRow
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import java.time.Instant
import java.time.format.TextStyle
import java.util.Locale

val BudgetScope.shortName: String
    get() = when (this) {
        BudgetScope.All -> localized("Total")
        is BudgetScope.Category -> category.shortName
    }

/** The donut card; tapping switches between the spending split and what's left, like `BudgetRingsCard`. */
@Composable
fun BudgetRingsCard(rings: BudgetRings, modifier: Modifier = Modifier) {
    var lens by remember { mutableStateOf(BudgetRings.Lens.SPLIT) }
    val canSwitch = rings.hasSpending
    val effectiveLens = if (canSwitch) lens else BudgetRings.Lens.SPLIT
    val isOverspentLens = effectiveLens == BudgetRings.Lens.LEFT_TO_SPEND && rings.isOverspent
    val title = when {
        effectiveLens == BudgetRings.Lens.SPLIT -> localized("Spending Split")
        isOverspentLens -> localized("Overspent")
        else -> localized("Left to Spend")
    }
    val caption = when {
        effectiveLens == BudgetRings.Lens.SPLIT -> localized("Spent")
        isOverspentLens -> localized("Over")
        else -> localized("Left")
    }
    TrenteCard(
        modifier = modifier.clickable(enabled = canSwitch) {
            lens = if (lens == BudgetRings.Lens.SPLIT) BudgetRings.Lens.LEFT_TO_SPEND else BudgetRings.Lens.SPLIT
        },
        label = title,
        icon = if (isOverspentLens) Icons.Default.Warning else Icons.Default.PieChart,
        iconTint = if (isOverspentLens) TrenteColors.red else MaterialTheme.colorScheme.onSurface,
        trailing = { if (canSwitch) Icon(Icons.Default.UnfoldMore, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(16.dp)) }
    ) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            BudgetRingsView(
                segments = rings.segments(effectiveLens),
                plan = rings.plan(effectiveLens),
                centerShare = rings.centerShare(effectiveLens),
                centerCaption = caption,
                isOverspent = isOverspentLens,
                showsCaptionAsAlert = isOverspentLens,
                modifier = Modifier.widthIn(max = 280.dp).fillMaxWidth()
            )
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            BudgetCategory.entries.forEach { category ->
                Row(Modifier.padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    CategoryDot(category.color, size = 8.dp)
                    Spacer(Modifier.width(4.dp))
                    Text(category.shortName, style = TrenteType.footnote, color = TrenteColors.secondaryText)
                }
            }
        }
    }
}

val budgetGaugeScopes: List<BudgetScope> = listOf(
    BudgetScope.All,
    BudgetScope.Category(BudgetCategory.NEEDS),
    BudgetScope.Category(BudgetCategory.WANTS),
    BudgetScope.Category(BudgetCategory.SAVINGS_AND_DEBTS)
)

/** Four gauges: the total and each category, like `BudgetGauges`. */
@Composable
fun BudgetGaugesCard(gauges: List<Pair<BudgetScope, BudgetFigures>>, currencyCode: String, modifier: Modifier = Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        gauges.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                row.forEach { (scope, figures) ->
                    GraphCard(scope = scope, figures = figures, currencyCode = currencyCode, modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun GraphCard(scope: BudgetScope, figures: BudgetFigures, currencyCode: String, modifier: Modifier = Modifier) {
    var showRemaining by remember { mutableStateOf(false) }
    val isOverspent = figures.isOverspent
    val displayed = if (showRemaining) figures.remaining else figures.spent
    TrenteCard(
        modifier = modifier.clickable { showRemaining = !showRemaining },
        label = scope.shortName,
        icon = if (isOverspent) Icons.Default.Warning else Icons.Default.PieChart,
        iconTint = if (isOverspent) TrenteColors.red else scope.color
    ) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            BudgetGaugeView(figures = figures, scope = scope, currencyCode = currencyCode, size = 80.dp, showRemaining = showRemaining, showsPercentage = true, modifier = Modifier.padding(8.dp))
            Row {
                Text(MoneyFormat.budget(displayed, currencyCode), style = TrenteType.caption, color = if (isOverspent) TrenteColors.red else MaterialTheme.colorScheme.onSurface, maxLines = 1)
                Text(" / ", style = TrenteType.caption, color = TrenteColors.secondaryText)
                Text(MoneyFormat.budget(figures.income, currencyCode), style = TrenteType.caption, color = TrenteColors.secondaryText, maxLines = 1)
            }
            Text(if (showRemaining) localized("Left") else localized("Spent"), style = TrenteType.caption, color = TrenteColors.secondaryText)
        }
    }
}

/** Stacked bars per day; tapping the card switches month and week, tapping a bar selects its day. */
@Composable
fun DailySpendingCard(spending: DailySpending, currencyCode: String, modifier: Modifier = Modifier, calendar: TrenteCalendar = TrenteCalendar.current) {
    var isWeek by remember { mutableStateOf(false) }
    var selectedDay by remember { mutableStateOf<Instant?>(null) }
    val hasData = spending.days.isNotEmpty()
    val weekStart = spending.defaultWeekStart
    val windowDays: List<DailySpend> = if (isWeek) spending.days(weekStart) else spending.days
    val title = when {
        !hasData -> localized("Daily Spending")
        isWeek -> if (spending.today != null && spending.weekWindow(weekStart).endInclusive >= spending.today!!) localized("Last 7 Days") else DateText.dayMonthWide(calendar.localDate(weekStart))
        spending.today != null -> localized("This Month")
        else -> DateText.monthYear(calendar.localDate(spending.monthStartDay))
    }
    TrenteCard(
        modifier = modifier.clickable(enabled = hasData) { isWeek = !isWeek; selectedDay = null },
        label = title,
        icon = Icons.Default.EventAvailable,
        trailing = { if (hasData) Icon(Icons.Default.UnfoldMore, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(16.dp)) }
    ) {
        if (!hasData) {
            Column(Modifier.fillMaxWidth().height(200.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Icon(Icons.Default.EventAvailable, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(40.dp))
                Spacer(Modifier.height(8.dp))
                Text(localized("No spending recorded yet."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            }
            return@TrenteCard
        }
        val firstDay = if (isWeek) weekStart else spending.monthStartDay
        val dayCount = if (isWeek) DailySpending.WEEK_LENGTH_IN_DAYS else spending.daysInMonth
        val maxTotal = (if (isWeek) spending.maxTotal(weekStart) else spending.maxTotal(null)).coerceAtLeast(1.0) * 1.2
        val categoryColors = BudgetCategory.entries.associateWith { it.color }
        val labelColor = TrenteColors.secondaryText.toArgb()
        val today = spending.today
        val highlight = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.06f)
        Canvas(
            Modifier
                .fillMaxWidth()
                .height(200.dp)
                .pointerInput(isWeek, firstDay) {
                    detectTapGestures { offset ->
                        val slot = size.width / dayCount
                        val index = (offset.x / slot).toInt().coerceIn(0, dayCount - 1)
                        val day = calendar.plusDays(firstDay, index.toLong())
                        selectedDay = if (selectedDay == day) null else day
                    }
                }
        ) {
            val labelHeight = 24.dp.toPx()
            val chartHeight = size.height - labelHeight
            val slot = size.width / dayCount
            val barWidth = slot * 0.6f
            val paint = android.graphics.Paint().apply { isAntiAlias = true; textSize = 10.sp.toPx(); color = labelColor; textAlign = android.graphics.Paint.Align.CENTER }
            for (index in 0 until dayCount) {
                val day = calendar.plusDays(firstDay, index.toLong())
                val x = slot * index + (slot - barWidth) / 2
                if (today != null && calendar.isSameDay(day, today)) {
                    drawRoundRect(highlight, topLeft = Offset(slot * index, 0f), size = Size(slot, chartHeight), cornerRadius = androidx.compose.ui.geometry.CornerRadius(6.dp.toPx()))
                }
                val spend = windowDays.firstOrNull { calendar.isSameDay(it.date, day) }
                if (spend != null) {
                    var bottom = chartHeight
                    val alpha = if (selectedDay == null || calendar.isSameDay(selectedDay!!, day)) 1f else 0.3f
                    BudgetCategory.entries.forEach { category ->
                        val amount = spend.amounts[category] ?: 0.0
                        if (amount > 0) {
                            val barHeight = (amount / maxTotal * chartHeight).toFloat()
                            drawRoundRect(categoryColors.getValue(category).copy(alpha = alpha), topLeft = Offset(x, bottom - barHeight), size = Size(barWidth, barHeight), cornerRadius = androidx.compose.ui.geometry.CornerRadius(3.dp.toPx()))
                            bottom -= barHeight
                        }
                    }
                }
                val local = calendar.localDate(day)
                val label = if (isWeek) local.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault()) else if (index % 5 == 0) local.dayOfMonth.toString() else null
                if (label != null) {
                    drawContext.canvas.nativeCanvas.drawText(label, slot * index + slot / 2, size.height - 6.dp.toPx(), paint)
                }
            }
        }
        val dockDays = selectedDay?.let { day -> listOfNotNull(spending.day(day)) } ?: windowDays
        val dockTitle = selectedDay?.let { DateText.fullDate(calendar.localDate(it)) } ?: localized("Total")
        val slices = CategorySlice.slices(dockDays)
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row {
                Text(dockTitle, style = TrenteType.caption.copy(fontWeight = FontWeight.Bold), modifier = Modifier.weight(1f))
                Text(MoneyFormat.amount(dockDays.sumOf { it.total }, currencyCode), style = TrenteType.caption.copy(fontWeight = FontWeight.Bold))
            }
            ProportionalBar(slices = slices.map { categoryColors.getValue(it.category) to it.amount })
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                slices.forEach { slice ->
                    Row(verticalAlignment = Alignment.Top) {
                        CategoryDot(categoryColors.getValue(slice.category), size = 6.dp, modifier = Modifier.padding(top = 4.dp))
                        Spacer(Modifier.width(4.dp))
                        Column {
                            Text(slice.category.shortName, style = TrenteType.caption2.copy(fontWeight = FontWeight.Bold))
                            Text(localized("%@ · %lld%%", MoneyFormat.amount(slice.amount, currencyCode), slice.percent), style = TrenteType.caption2, color = TrenteColors.secondaryText)
                        }
                    }
                }
            }
        }
    }
}

/** "Latest Transactions", like `MonthView+LatestTransactions`. */
@Composable
fun LatestTransactionsCard(
    latest: List<TransactionGroup>,
    hasAnyTransaction: Boolean,
    onSeeAll: () -> Unit,
    onOpen: (TransactionGroup) -> Unit,
    onEdit: (TransactionGroup) -> Unit,
    onDelete: (TransactionGroup) -> Unit,
    modifier: Modifier = Modifier
) {
    TrenteCard(modifier = modifier, label = localized("Latest Transactions"), icon = Icons.Default.History) {
        latest.forEachIndexed { index, group ->
            TransactionGroupRow(group = group, onOpen = { onOpen(group) }, onEdit = { onEdit(group) }, onDelete = { onDelete(group) })
            if (index < latest.size - 1) RowDivider()
        }
        when {
            !hasAnyTransaction -> Text(localized("Add your first transaction by tapping 'Add Transaction'."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            latest.isEmpty() -> Text(localized("Add your first transaction for this month by tapping 'Add Transaction'."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
        }
        if (hasAnyTransaction) {
            TrenteSecondaryButton(text = localized("See all transactions"), onClick = onSeeAll, narrow = true)
        }
    }
}

/** "Expected This Month", like `MonthView+UpcomingRecurring`. */
@Composable
fun UpcomingRecurringCard(
    occurrences: List<RecurringTransactionOccurrence>,
    count: Int,
    hasRules: Boolean,
    onSeeAll: () -> Unit,
    onOpen: (RecurringTransactionOccurrence) -> Unit,
    onConfirm: (RecurringTransactionOccurrence) -> Unit,
    onSkip: (RecurringTransactionOccurrence) -> Unit,
    modifier: Modifier = Modifier
) {
    val shown = occurrences.take(count)
    TrenteCard(modifier = modifier, label = localized("Expected This Month"), icon = Icons.Default.EventAvailable) {
        shown.forEachIndexed { index, occurrence ->
            RecurringOccurrenceRow(occurrence = occurrence, onOpen = { onOpen(occurrence) }, onConfirm = { onConfirm(occurrence) }, onSkip = { onSkip(occurrence) })
            if (index < shown.size - 1) RowDivider()
        }
        when {
            !hasRules -> Text(localized("Add your first Recurring Transaction by tapping 'Add Transaction'."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
            shown.isEmpty() -> Text(localized("Nothing else expected this month."), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
        }
        if (hasRules) {
            TrenteSecondaryButton(text = localized("See all expected"), onClick = onSeeAll, narrow = true)
        }
    }
}

/** One pending occurrence: due date, amount, split, Mark as Paid / Skip, and the schedule, like `RecurringOccurrenceSheet`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecurringOccurrenceSheet(
    occurrence: RecurringTransactionOccurrence,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit,
    onSkip: () -> Unit,
    onOpenRule: () -> Unit,
    calendar: TrenteCalendar = TrenteCalendar.current
) {
    var isSkipping by remember { mutableStateOf(false) }
    val currencyCode = occurrence.month.currency.isoCode
    val day = calendar.localDate(occurrence.date)
    val dayText = DateText.dayMonthWide(day)
    val isOverdue = occurrence.isOverdue(calendar = calendar)
    val isToday = calendar.isSameDay(occurrence.date, Instant.now())
    val dueText = when {
        isOverdue -> localized("Overdue since %@", dayText)
        isToday -> localized("Due today")
        else -> localized("Due %@", dayText)
    }
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = MaterialTheme.colorScheme.background) {
        Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(occurrence.rule.title, style = TrenteType.headline, modifier = Modifier.padding(bottom = 4.dp))
            TrenteCard {
                Text(dueText, style = TrenteType.subheadline, color = if (isOverdue) TrenteColors.orange else TrenteColors.secondaryText)
                Text(MoneyFormat.amountCents(occurrence.amountCents, currencyCode), style = TrenteType.largeTitle.copy(fontWeight = FontWeight.SemiBold))
                val repartition = occurrence.rule.repartition.filterValues { it != 0 }
                repartition.forEach { (category, cents) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CategoryDot(category.color)
                        Spacer(Modifier.width(8.dp))
                        Text(category.displayName, style = TrenteType.subheadline, color = TrenteColors.secondaryText, modifier = Modifier.weight(1f))
                        if (repartition.size > 1) {
                            Text(MoneyFormat.amountCents(cents, currencyCode), style = TrenteType.subheadline)
                        }
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                TrentePrimaryButton(
                    text = if (occurrence.isIncome) localized("Mark as Received") else localized("Mark as Paid"),
                    icon = Icons.Default.CheckCircle,
                    narrow = true,
                    onClick = onConfirm,
                    modifier = Modifier.weight(1f)
                )
                TrenteSecondaryButton(
                    text = when (occurrence.rule.frequency) {
                        app.trente.core.model.RecurrenceFrequency.WEEKLY -> localized("Skip This Week")
                        app.trente.core.model.RecurrenceFrequency.MONTHLY -> localized("Skip This Month")
                        app.trente.core.model.RecurrenceFrequency.YEARLY -> localized("Skip This Year")
                    },
                    icon = Icons.Default.SkipNext,
                    narrow = true,
                    onClick = { isSkipping = true },
                    modifier = Modifier.weight(1f)
                )
            }
            TrenteCard(label = localized("Schedule"), icon = Icons.Default.History) {
                Row(Modifier.fillMaxWidth().clickable(onClick = onOpenRule), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(occurrence.rule.frequencyDescription(), style = TrenteType.headline)
                        Text(localized("Change or stop this schedule"), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = TrenteColors.secondaryText)
                }
            }
        }
    }
    if (isSkipping) {
        SkipOccurrenceDialog(occurrence = occurrence, onDismiss = { isSkipping = false }, onSkip = { isSkipping = false; onSkip() }, calendar = calendar)
    }
}
