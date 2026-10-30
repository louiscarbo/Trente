package app.trente.core.services

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteDates
import app.trente.core.model.TrenteStore
import java.time.Instant
import kotlin.math.abs

/** What the new transaction flow collects. The amount always carries the sign of the type. */
class TransactionCreationRequest {
    var title: String = ""

    var amountCents: Int = 0
        set(value) {
            field = signed(value)
        }

    var type: TransactionType = TransactionType.EXPENSE
        set(value) {
            field = value
            amountCents = amountCents
            if (value == TransactionType.INCOME) {
                selectedCategory = null
            }
        }

    var selectedCategory: BudgetCategory? = null
    var notes: String = ""
    var imageData: ByteArray? = null
    var isRecurrent: Boolean = false
    var date: Instant = Instant.now()

    var repartition: Map<BudgetCategory, Int> = emptyMap()

    var recurrenceFrequency: RecurrenceFrequency = RecurrenceFrequency.MONTHLY
    var recurrenceStartDate: Instant = Instant.now()
    var recurrenceEndDate: Instant? = null

    private fun signed(cents: Int): Int = if (type == TransactionType.INCOME) abs(cents) else -abs(cents)
}

sealed class TransactionServiceError(message: String) : Exception(message) {
    class MissingCategoryForExpense : TransactionServiceError("An expense needs a category.")
    class InvalidRepartition : TransactionServiceError("An income needs at least one category with an amount.")
    class RecurrenceStartsInPast : TransactionServiceError("A recurring transaction cannot start in the past.")
}

object TransactionService {
    fun fetchTransactionDateBounds(store: TrenteStore): ClosedRange<Instant> {
        val dates = store.transactionGroups.map { it.addedDate }
        val earliest = dates.minOrNull() ?: TrenteDates.distantPast
        val latest = dates.maxOrNull() ?: TrenteDates.distantFuture
        return earliest..latest
    }

    fun delete(group: TransactionGroup, store: TrenteStore) {
        store.delete(group)
    }

    fun create(
        request: TransactionCreationRequest,
        month: Month,
        store: TrenteStore,
        now: Instant = Instant.now(),
        calendar: TrenteCalendar = TrenteCalendar.current
    ) {
        insert(request, month, store, now, calendar)
        store.save()
    }

    fun insert(
        request: TransactionCreationRequest,
        month: Month,
        store: TrenteStore,
        now: Instant = Instant.now(),
        calendar: TrenteCalendar = TrenteCalendar.current
    ) {
        if (request.isRecurrent) {
            if (request.recurrenceStartDate < calendar.startOfDay(now)) {
                throw TransactionServiceError.RecurrenceStartsInPast()
            }
            val rule = RecurringTransactionRule(
                title = request.title,
                frequency = request.recurrenceFrequency,
                startDate = request.recurrenceStartDate,
                endDate = request.recurrenceEndDate,
                repartition = recurringRepartition(request),
                createdAt = now
            )
            store.insert(rule)
        } else {
            createTransactionGroupWithEntries(request, month)
        }
    }

    private fun recurringRepartition(request: TransactionCreationRequest): Map<BudgetCategory, Int> = when (request.type) {
        TransactionType.EXPENSE -> {
            val category = request.selectedCategory ?: throw TransactionServiceError.MissingCategoryForExpense()
            mapOf(category to request.amountCents)
        }
        TransactionType.INCOME -> {
            val repartition = request.repartition.filterValues { it > 0 }
            if (repartition.isEmpty()) throw TransactionServiceError.InvalidRepartition()
            repartition
        }
    }

    private fun createTransactionGroupWithEntries(request: TransactionCreationRequest, month: Month): TransactionGroup {
        if (request.type == TransactionType.EXPENSE && request.selectedCategory == null) {
            throw TransactionServiceError.MissingCategoryForExpense()
        }
        if (request.type == TransactionType.INCOME && request.repartition.values.none { it > 0 }) {
            throw TransactionServiceError.InvalidRepartition()
        }

        val group = TransactionGroup(
            title = request.title,
            type = request.type,
            month = month,
            note = request.notes.ifEmpty { null },
            imageAttachmentData = request.imageData,
            addedDate = request.date
        )

        val category = request.selectedCategory
        if (request.type == TransactionType.EXPENSE && category != null) {
            TransactionEntry(amountCents = request.amountCents, category = category, group = group)
        } else if (request.type == TransactionType.INCOME) {
            for ((entryCategory, amount) in request.repartition) {
                if (amount > 0) TransactionEntry(amountCents = amount, category = entryCategory, group = group)
            }
        }
        return group
    }
}
