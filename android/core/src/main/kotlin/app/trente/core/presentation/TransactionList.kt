package app.trente.core.presentation

import app.trente.core.model.BudgetCategory
import app.trente.core.model.DateInterval
import app.trente.core.model.Month
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TrenteCalendar
import app.trente.core.support.DateText
import app.trente.core.support.MoneyFormat
import app.trente.core.support.TextSearch
import java.time.Instant
import java.util.UUID

enum class SortOption { DATE_ASC, DATE_DESC, AMOUNT_ASC, AMOUNT_DESC, TITLE_ASC, TITLE_DESC }

/** A row of the transaction list: a recorded transaction or a pending occurrence. */
sealed class DisplayableTransaction {
    data class Group(val group: TransactionGroup) : DisplayableTransaction()
    data class Recurring(val occurrence: RecurringTransactionOccurrence) : DisplayableTransaction()

    sealed class ID {
        data class Group(val id: UUID) : ID()
        data class Recurring(val key: RecurringTransactionOccurrence.Key) : ID()
    }

    val id: ID
        get() = when (this) {
            is Group -> ID.Group(group.id)
            is Recurring -> ID.Recurring(occurrence.id)
        }

    val date: Instant
        get() = when (this) {
            is Group -> group.addedDate
            is Recurring -> occurrence.date
        }

    val title: String
        get() = when (this) {
            is Group -> group.title
            is Recurring -> occurrence.rule.title
        }

    val categories: List<BudgetCategory>
        get() = when (this) {
            is Group -> group.entries.map { it.category }
            is Recurring -> occurrence.rule.repartition.keys.toList()
        }

    val amountCents: Int
        get() = when (this) {
            is Group -> group.totalAmountCents
            is Recurring -> occurrence.rule.amountCents
        }

    val currencyCode: String
        get() = when (this) {
            is Group -> group.currency.isoCode
            is Recurring -> occurrence.month.currency.isoCode
        }

    val displayAmount: String get() = MoneyFormat.amount(amountCents / 100.0, currencyCode)

    fun searchableString(calendar: TrenteCalendar = TrenteCalendar.current): String {
        val delimiter = "\u001F"
        val categoryNames = categories.joinToString(delimiter) { it.displayName }
        val dateText = DateText.fullDate(calendar.localDate(date))
        return title + delimiter + categoryNames + delimiter + dateText + delimiter + displayAmount
    }
}

class TransactionListFilter(month: Month, private val calendar: TrenteCalendar = TrenteCalendar.current) {
    var searchText: String = ""
    var firstDay: Instant = month.startDate
    var lastDay: Instant = month.endDate(calendar)
    var categories: Set<BudgetCategory> = emptySet()
    var sort: SortOption = SortOption.DATE_DESC

    /** Only dates and categories count as active filters. */
    fun isActive(month: Month): Boolean =
        categories.isNotEmpty() || firstDay != month.startDate || lastDay != month.endDate(calendar)

    /** Clears search, dates and categories but keeps the sort order. */
    fun reset(month: Month) {
        searchText = ""
        firstDay = month.startDate
        lastDay = month.endDate(calendar)
        categories = emptySet()
    }

    fun apply(items: List<DisplayableTransaction>): List<DisplayableTransaction> {
        val shownDays = days(firstDay, lastDay, calendar)
        val comparator: Comparator<DisplayableTransaction> = when (sort) {
            SortOption.DATE_ASC -> compareBy { it.date }
            SortOption.DATE_DESC -> compareByDescending { it.date }
            SortOption.AMOUNT_ASC -> compareBy { it.amountCents }
            SortOption.AMOUNT_DESC -> compareByDescending { it.amountCents }
            SortOption.TITLE_ASC -> compareBy { it.title }
            SortOption.TITLE_DESC -> compareByDescending { it.title }
        }
        return items
            .filter { searchText.isEmpty() || TextSearch.contains(it.searchableString(calendar), searchText) }
            .filter { it.date in shownDays }
            .filter { item -> categories.isEmpty() || item.categories.any { it in categories } }
            .sortedWith(comparator)
    }

    fun totalCents(items: List<DisplayableTransaction>): Int = items.sumOf { it.amountCents }

    companion object {
        /** Every instant from the start of the first day through the end of the last day. */
        fun days(from: Instant, through: Instant, calendar: TrenteCalendar = TrenteCalendar.current): DateInterval {
            val firstDay = calendar.startOfDay(from)
            val lastDay = calendar.startOfDay(through)
            val dayAfterLastDay = calendar.plusDays(lastDay, 1)
            return DateInterval(firstDay, maxOf(firstDay, dayAfterLastDay))
        }
    }
}
