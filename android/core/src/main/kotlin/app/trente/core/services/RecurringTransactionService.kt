package app.trente.core.services

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Month
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteDates
import app.trente.core.model.TrenteStore
import java.time.Instant

object RecurringTransactionService {
    fun pendingOccurrences(
        rules: List<RecurringTransactionRule>,
        month: Month,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): List<RecurringTransactionOccurrence> =
        rules.flatMap { it.pendingOccurrences(month, calendar) }.sortedBy { it.date }

    /** Records the occurrence by hand: the transaction is dated now. */
    fun confirm(
        occurrence: RecurringTransactionOccurrence,
        store: TrenteStore,
        addedDate: Instant = Instant.now(),
        calendar: TrenteCalendar = TrenteCalendar.current
    ) {
        if (!insertTransaction(occurrence, store, addedDate, calendar)) return
        store.save()
    }

    /**
     * Records every automatic occurrence due today or earlier, dated on its due day.
     * The checkpoint moves even without Trente+, so a subscription taken later is not retroactive.
     */
    fun confirmDueOccurrences(
        store: TrenteStore,
        now: Instant = Instant.now(),
        isAutomaticUnlocked: Boolean,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): Int {
        val rules = store.rules.filter { it.autoConfirm }
        val earliestCheckpoint = rules.map { it.lastAutoConfirmedDate ?: it.startDate }.minOrNull() ?: return 0

        val firstMonthStart = calendar.plusMonths(earliestCheckpoint, -1)
        val months = store.months.filter { it.startDate >= firstMonthStart && it.startDate <= now }
        val dueOccurrences = months.flatMap { month ->
            rules.flatMap { it.dueAutomaticOccurrences(month, now, calendar) }
        }
        if (dueOccurrences.isEmpty()) return 0

        for (occurrence in dueOccurrences) {
            val rule = occurrence.rule
            rule.lastAutoConfirmedDate = maxOf(rule.lastAutoConfirmedDate ?: TrenteDates.distantPast, occurrence.date)
            if (isAutomaticUnlocked) {
                insertTransaction(occurrence, store, addedDate = occurrence.date, calendar = calendar)
            }
        }
        store.save()
        return if (isAutomaticUnlocked) dueOccurrences.size else 0
    }

    fun insertTransaction(
        occurrence: RecurringTransactionOccurrence,
        store: TrenteStore,
        addedDate: Instant,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): Boolean {
        val rule = occurrence.rule
        if (rule.isSettled(occurrence.date, calendar)) return false

        val group = TransactionGroup(
            title = rule.title,
            type = if (occurrence.amountCents < 0) TransactionType.EXPENSE else TransactionType.INCOME,
            month = occurrence.month,
            note = null,
            imageAttachmentData = null,
            addedDate = addedDate
        )
        group.recurringRule = rule
        group.recurringOccurrenceDate = occurrence.date

        for (category in BudgetCategory.entries) {
            val amount = rule.repartition[category] ?: continue
            if (amount == 0) continue
            TransactionEntry(amountCents = amount, category = category, group = group)
        }
        return true
    }

    fun skip(occurrence: RecurringTransactionOccurrence, store: TrenteStore, calendar: TrenteCalendar = TrenteCalendar.current) {
        val rule = occurrence.rule
        if (rule.isSkipped(occurrence.date, calendar)) return
        rule.skippedOccurrenceDates = rule.skippedOccurrenceDates + occurrence.date
        store.save()
    }

    /** Keeps today's payment and drops the following ones. */
    fun stop(rule: RecurringTransactionRule, store: TrenteStore, now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current) {
        rule.endDate = calendar.startOfDay(now)
        store.save()
    }

    fun delete(rule: RecurringTransactionRule, store: TrenteStore) {
        store.delete(rule)
    }
}
