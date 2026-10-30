package app.trente.core.model

import app.trente.core.support.DateText
import app.trente.core.support.localized
import java.time.Instant
import java.util.Locale
import java.util.UUID

/**
 * A transaction that repeats. The single source of truth for both the schedule and the template.
 * See `Trente/Model/README.md` in the iOS project for the full explanation.
 */
class RecurringTransactionRule(
    title: String,
    frequency: RecurrenceFrequency,
    startDate: Instant,
    endDate: Instant? = null,
    autoConfirm: Boolean = false,
    repartition: Map<BudgetCategory, Int>,
    createdAt: Instant = Instant.now(),
    val id: UUID = UUID.randomUUID()
) {
    var title: String = title
    var frequency: RecurrenceFrequency = frequency
    var startDate: Instant = startDate
    var endDate: Instant? = endDate
    var autoConfirm: Boolean = autoConfirm
    var createdAt: Instant = createdAt
    var skippedOccurrenceDates: List<Instant> = emptyList()
    var lastAutoConfirmedDate: Instant? = null

    /** Signed like entries: negative = expense (exactly one category), positive = income (split across categories). */
    var repartition: Map<BudgetCategory, Int> = validated(repartition)
        set(value) {
            field = validated(value)
        }

    internal val mutableTransactions = mutableListOf<TransactionGroup>()

    val transactions: List<TransactionGroup> get() = mutableTransactions

    val amountCents: Int get() = repartition.values.sum()

    val schedule: RecurrenceSchedule
        get() = RecurrenceSchedule(frequency = frequency, startDate = startDate, endDate = endDate, earliestDate = createdAt)

    fun occurrences(month: Month, calendar: TrenteCalendar = TrenteCalendar.current): List<RecurringTransactionOccurrence> =
        schedule.dates(month.dateInterval(calendar), calendar).map { date -> RecurringTransactionOccurrence(this, date, month) }

    fun hasEnded(now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): Boolean {
        val end = endDate ?: return false
        return calendar.startOfDay(end) <= calendar.startOfDay(now)
    }

    fun pendingOccurrences(month: Month, calendar: TrenteCalendar = TrenteCalendar.current): List<RecurringTransactionOccurrence> =
        occurrences(month, calendar).filter { isPending(it.date, calendar) }

    fun isPending(date: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Boolean =
        !isSettled(date, calendar) && !isSkipped(date, calendar)

    fun dueAutomaticOccurrences(
        month: Month,
        by: Instant,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): List<RecurringTransactionOccurrence> {
        if (!autoConfirm) return emptyList()
        val checkpoint = lastAutoConfirmedDate ?: TrenteDates.distantPast
        return pendingOccurrences(month, calendar).filter { it.date <= by && it.date > checkpoint }
    }

    fun isSettled(date: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Boolean =
        transactions.any { transaction ->
            val settledDate = transaction.recurringOccurrenceDate ?: return@any false
            isSamePeriod(settledDate, date, calendar)
        }

    fun isSkipped(date: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Boolean =
        skippedOccurrenceDates.any { isSamePeriod(it, date, calendar) }

    private fun isSamePeriod(lhs: Instant, rhs: Instant, calendar: TrenteCalendar): Boolean =
        calendar.isSame(lhs, rhs, frequency.granularity)

    /** "Every Monday", "Every month on the 15th", "Every October 27". */
    fun frequencyDescription(
        calendar: TrenteCalendar = TrenteCalendar.current,
        localization: String = Locale.getDefault().toLanguageTag()
    ): String {
        val day = calendar.localDate(startDate)
        return when (frequency) {
            RecurrenceFrequency.WEEKLY -> localized("Every %@", DateText.weekdayWide(day))
            RecurrenceFrequency.MONTHLY -> localized("Every month on the %@", day.dayOfMonth.dayOfMonthString(localization))
            RecurrenceFrequency.YEARLY -> localized("Every %@", DateText.monthWideDay(day))
        }
    }

    override fun toString(): String = "RecurringTransactionRule($title, $id)"

    private companion object {
        fun validated(repartition: Map<BudgetCategory, Int>): Map<BudgetCategory, Int> {
            val total = repartition.values.sum()
            require(total >= 0 || repartition.size <= 1) {
                "Expense rule repartition must contain exactly one category, got ${repartition.size}."
            }
            return repartition
        }
    }
}

/** The day of the month as an ordinal in the languages whose sentence needs one ("15th", "15."), plain elsewhere. */
fun Int.dayOfMonthString(localization: String = Locale.getDefault().toLanguageTag()): String {
    val languageCode = localization.split('-', '_').first().lowercase()
    return when (languageCode) {
        "en" -> {
            val suffix = when {
                this % 100 in 11..13 -> "th"
                this % 10 == 1 -> "st"
                this % 10 == 2 -> "nd"
                this % 10 == 3 -> "rd"
                else -> "th"
            }
            "$this$suffix"
        }
        "de" -> "$this."
        else -> "$this"
    }
}

/** The schedule of a rule: which days it falls on inside an interval. */
data class RecurrenceSchedule(
    val frequency: RecurrenceFrequency,
    val startDate: Instant,
    val endDate: Instant?,
    val earliestDate: Instant
) {
    /**
     * Anchored on the start day, clamping the 31st to the last day of shorter months and February 29 to the 28th,
     * ignoring the time of day. Nothing before the start day or the earliest day, nothing after the end day.
     */
    fun dates(interval: DateInterval, calendar: TrenteCalendar = TrenteCalendar.current): List<Instant> {
        val unit = frequency.chronoUnit
        val anchor = calendar.startOfDay(startDate)
        val lowerBound = maxOf(anchor, calendar.startOfDay(earliestDate), calendar.startOfDay(interval.start))
        val upperBound = exclusiveUpperBound(interval, calendar)
        if (lowerBound >= upperBound) return emptyList()

        val elapsedPeriods = calendar.wholeUnitsBetween(anchor, lowerBound, unit)
        var index = maxOf(0, elapsedPeriods - 1)
        val dates = mutableListOf<Instant>()
        while (true) {
            val date = calendar.plus(anchor, unit, index)
            if (date >= upperBound) break
            if (date >= lowerBound) dates.add(date)
            index += 1
        }
        return dates
    }

    fun firstDate(onOrAfter: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Instant? {
        val start = calendar.startOfDay(onOrAfter)
        val end = calendar.plus(start, frequency.chronoUnit, 1)
        return dates(DateInterval(start, end), calendar).firstOrNull()
    }

    private fun exclusiveUpperBound(interval: DateInterval, calendar: TrenteCalendar): Instant {
        val end = endDate ?: return interval.end
        val dayAfterEnd = calendar.plusDays(calendar.startOfDay(end), 1)
        return minOf(interval.end, dayAfterEnd)
    }
}

/** One expected payment of a rule on one day, inside one month. Computed, never stored. */
data class RecurringTransactionOccurrence(
    val rule: RecurringTransactionRule,
    val date: Instant,
    val month: Month
) {
    data class Key(val ruleID: UUID, val date: Instant)

    val id: Key get() = Key(rule.id, date)

    val amountCents: Int get() = rule.amountCents

    fun amountCents(scope: BudgetScope): Int = when (scope) {
        BudgetScope.All -> amountCents
        is BudgetScope.Category -> rule.repartition[scope.category] ?: 0
    }

    val isIncome: Boolean get() = amountCents > 0

    fun isOverdue(now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): Boolean =
        date < calendar.startOfDay(now)

    val categoryName: String
        get() {
            if (amountCents < 0) {
                rule.repartition.keys.firstOrNull()?.let { return it.shortName }
            }
            return localized("Income")
        }
}
