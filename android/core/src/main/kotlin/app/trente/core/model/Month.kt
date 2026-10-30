package app.trente.core.model

import app.trente.core.support.DateText
import java.time.Instant
import java.util.Locale
import java.util.UUID
import kotlin.math.abs
import kotlin.math.max

/**
 * One budget month: it starts on `startDate` and lasts one calendar month.
 *
 * Transactions attach themselves through [TransactionGroup.month]; the list here is read-only.
 */
class Month(
    startDate: Instant,
    currency: Currency,
    idealBudgetCents: Int,
    idealRepartition: Map<BudgetCategory, Int>,
    val id: UUID = UUID.randomUUID()
) {
    var startDate: Instant = startDate
    var modifiedDate: Instant? = null
    var currency: Currency = currency
    var idealBudgetCents: Int = idealBudgetCents
    var idealRepartition: Map<BudgetCategory, Int> = idealRepartition

    internal val mutableGroups = mutableListOf<TransactionGroup>()

    val transactionGroups: List<TransactionGroup> get() = mutableGroups

    val name: String get() = name(startDate)

    private val transactionEntries: List<TransactionEntry> get() = transactionGroups.flatMap { it.entries }

    private val remainingAmountCents: Int get() = transactionEntries.sumOf { it.amountCents }

    private val spentAmountCents: Int get() = transactionEntries.filter { it.amountCents < 0 }.sumOf { it.amountCents }

    private val incomeAmountCents: Int get() = transactionEntries.filter { it.amountCents > 0 }.sumOf { it.amountCents }

    val remainingAmount: Double get() = remainingAmountCents / 100.0

    val incomeAmount: Double get() = incomeAmountCents / 100.0

    val overSpent: Boolean get() = remainingAmountCents < 0

    /** What was spent in a category, as a positive amount, not in cents. */
    fun spentAmount(category: BudgetCategory): Double {
        val categoryCents = transactionEntries.filter { it.category == category && it.amountCents < 0 }.sumOf { it.amountCents }
        return abs(categoryCents / 100.0)
    }

    fun incomeAmount(category: BudgetCategory): Double {
        val categoryCents = transactionEntries.filter { it.category == category && it.amountCents > 0 }.sumOf { it.amountCents }
        return categoryCents / 100.0
    }

    fun remainingAmount(category: BudgetCategory): Double = incomeAmount(category) - spentAmount(category)

    fun overSpending(category: BudgetCategory): Boolean = remainingAmount(category) < 0

    fun spentAmount(scope: BudgetScope): Double = when (scope) {
        BudgetScope.All -> abs(spentAmountCents / 100.0)
        is BudgetScope.Category -> spentAmount(scope.category)
    }

    fun incomeAmount(scope: BudgetScope): Double = when (scope) {
        BudgetScope.All -> incomeAmount
        is BudgetScope.Category -> incomeAmount(scope.category)
    }

    fun remainingAmount(scope: BudgetScope): Double = when (scope) {
        BudgetScope.All -> remainingAmount
        is BudgetScope.Category -> remainingAmount(scope.category)
    }

    fun overSpending(scope: BudgetScope): Boolean = remainingAmount(scope) < 0

    fun figures(scope: BudgetScope): BudgetFigures = BudgetFigures(
        spent = spentAmount(scope),
        income = incomeAmount(scope),
        remaining = remainingAmount(scope)
    )

    /** The month's figures as if the given occurrences (automatic ones not recorded yet) were already recorded. */
    fun figures(scope: BudgetScope, occurrences: List<RecurringTransactionOccurrence>): BudgetFigures =
        occurrences.fold(figures(scope)) { figures, occurrence ->
            val amount = occurrence.amountCents(scope) / 100.0
            BudgetFigures(
                spent = figures.spent + max(0.0, -amount),
                income = figures.income + max(0.0, amount),
                remaining = figures.remaining + amount
            )
        }

    fun endDate(calendar: TrenteCalendar = TrenteCalendar.current): Instant = calendar.plusDays(dateInterval(calendar).end, -1)

    val dateInterval: DateInterval get() = dateInterval(TrenteCalendar.current)

    fun dateInterval(calendar: TrenteCalendar): DateInterval {
        val start = calendar.startOfDay(startDate)
        return DateInterval(start, calendar.plusMonths(start, 1))
    }

    fun contains(date: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Boolean = date in dateInterval(calendar)

    val latestTransactions: List<TransactionGroup> get() = transactionGroups.sortedByDescending { it.addedDate }

    override fun toString(): String = "Month($name, $id)"

    companion object {
        /** "October 2026", capitalized like the start of a sentence. */
        fun name(startDate: Instant, calendar: TrenteCalendar = TrenteCalendar.current): String =
            DateText.monthYear(calendar.localDate(startDate))
                .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }
}
