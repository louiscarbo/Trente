package app.trente.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.Currencies
import app.trente.core.model.TrenteCalendar
import app.trente.core.presentation.MonthDraft
import app.trente.core.support.DateText
import app.trente.core.support.localized
import app.trente.ui.theme.TrenteType
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

/** A date row that opens the Material date picker, standing in for a compact `DatePicker`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DateField(
    label: String,
    date: Instant,
    onDateChange: (Instant) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    minDate: Instant? = null,
    maxDate: Instant? = null,
    calendar: TrenteCalendar = TrenteCalendar.current
) {
    var isPicking by remember { mutableStateOf(false) }
    val localDate = calendar.localDate(date)
    Row(
        modifier = modifier.fillMaxWidth().clickable(enabled = enabled) { isPicking = true }.padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, style = TrenteType.body)
        Spacer(Modifier.weight(1f))
        androidx.compose.material3.Surface(
            shape = androidx.compose.foundation.shape.RoundedCornerShape(8.dp),
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = if (enabled) 1f else 0.5f)
        ) {
            Text(DateText.mediumDate(localDate), style = TrenteType.body, modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp))
        }
    }
    if (isPicking) {
        val minDay = minDate?.let { calendar.localDate(it) }
        val maxDay = maxDate?.let { calendar.localDate(it) }
        val state = rememberDatePickerState(
            initialSelectedDateMillis = localDate.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
            selectableDates = object : SelectableDates {
                override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                    val day = Instant.ofEpochMilli(utcTimeMillis).atZone(ZoneOffset.UTC).toLocalDate()
                    return (minDay == null || !day.isBefore(minDay)) && (maxDay == null || !day.isAfter(maxDay))
                }
            }
        )
        DatePickerDialog(
            onDismissRequest = { isPicking = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let { millis ->
                        val picked = Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()
                        onDateChange(withDay(date, picked, calendar))
                    }
                    isPicking = false
                }) { Text(localized("Done")) }
            },
            dismissButton = { TextButton(onClick = { isPicking = false }) { Text(localized("Cancel")) } }
        ) {
            DatePicker(state = state)
        }
    }
}

/** Keeps the time of day of `date` and moves it to `day`. */
private fun withDay(date: Instant, day: LocalDate, calendar: TrenteCalendar): Instant {
    val zoned = calendar.zoned(date)
    return day.atTime(zoned.toLocalTime()).atZone(calendar.zone).toInstant()
}

@Composable
fun MonthCurrencyPicker(currencyCode: String, onCurrencyChange: (app.trente.core.model.Currency) -> Unit, modifier: Modifier = Modifier) {
    val currencies = remember { Currencies.availableCurrencies.sortedBy { it.displayName } }
    val selection = Currencies.currency(currencyCode) ?: app.trente.core.model.Currency.fallback
    LabeledPicker(
        title = localized("Currency"),
        selection = selection,
        options = currencies,
        onSelect = onCurrencyChange,
        modifier = modifier,
        optionTitle = { "${it.symbol}  ${it.displayName}" }
    )
}

/** The month editor shared by the new month screen and the month details, like `MonthDetailsComponent`. */
@Composable
fun MonthDetailsComponent(
    draft: MonthDraft,
    onDraftChange: (MonthDraft) -> Unit,
    onRepartitionCompleteChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        TrenteCard(label = localized("Month Details"), icon = Icons.Default.CalendarMonth) {
            DateField(label = localized("Start Date"), date = draft.startDate, onDateChange = { onDraftChange(draft.copy(startDate = it)) })
            MonthCurrencyPicker(currencyCode = draft.currency.isoCode, onCurrencyChange = { onDraftChange(draft.copy(currency = it)) })
        }
        TrenteCard(label = localized("Ideal Budget"), icon = Icons.Default.Speed) {
            CurrencyTextField(
                amountCents = draft.idealBudgetCents,
                onAmountChange = { newBudget ->
                    val repartition = if (newBudget < draft.idealBudgetCents) BudgetCategory.entries.associateWith { 0 } else draft.idealRepartition
                    onDraftChange(draft.copy(idealBudgetCents = newBudget, idealRepartition = repartition))
                },
                currencyCode = draft.currency.isoCode,
                textStyle = TrenteType.title,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            if (draft.idealBudgetCents > 0) {
                IncomeRepartitionComponent(
                    repartition = draft.idealRepartition,
                    amountToSplit = draft.idealBudgetCents,
                    currencyCode = draft.currency.isoCode,
                    onRepartitionChange = { onDraftChange(draft.copy(idealRepartition = it)) },
                    onCompleteChange = onRepartitionCompleteChange
                )
            } else {
                androidx.compose.runtime.LaunchedEffect(Unit) { onRepartitionCompleteChange(false) }
            }
        }
    }
}
