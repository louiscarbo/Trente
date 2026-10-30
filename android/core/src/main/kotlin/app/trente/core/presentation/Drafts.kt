package app.trente.core.presentation

import app.trente.core.model.BudgetCategory
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.support.localized
import java.time.Instant
import kotlin.math.abs
import kotlin.math.max

/** What the transaction details screen edits. Value-like, so discarding is just dropping it. */
class TransactionGroupDraft private constructor(
    var title: String,
    var note: String,
    var imageAttachmentData: ByteArray?,
    val type: TransactionType
) {
    // Expense-only fields
    var expenseCategory: BudgetCategory? = null

    var expenseAmountCents: Int = 0
        set(value) {
            field = if (value > 0) -value else value
        }

    // Income-only fields: the repartition per category must sum to the amount to split.
    var incomeRepartition: Map<BudgetCategory, Int> = emptyMap()
    var incomeAmountToSplitCents: Int = 0

    fun apply(group: TransactionGroup, store: TrenteStore) {
        group.title = title
        group.note = note.ifEmpty { null }
        group.imageAttachmentData = imageAttachmentData

        when (type) {
            TransactionType.EXPENSE -> {
                val category = expenseCategory
                val amount = expenseAmountCents
                val entries = group.entries.toList()
                if (entries.isEmpty()) {
                    TransactionEntry(amountCents = amount, category = category ?: BudgetCategory.NEEDS, group = group)
                } else {
                    entries[0].category = category ?: entries[0].category
                    entries[0].amountCents = amount
                    entries.drop(1).forEach { store.delete(it) }
                }
            }
            TransactionType.INCOME -> {
                group.entries.toList().forEach { store.delete(it) }
                for ((category, cents) in incomeRepartition) {
                    if (cents != 0) TransactionEntry(amountCents = cents, category = category, group = group)
                }
            }
        }
        group.modifiedDate = Instant.now()
    }

    fun fillMissingAmountToSplit() {
        if (type != TransactionType.INCOME || incomeAmountToSplitCents != 0) return
        incomeAmountToSplitCents = incomeRepartition.values.sum()
    }

    fun validate(): List<String> {
        val issues = mutableListOf<String>()
        if (title.trim().isEmpty()) {
            issues.add(localized("Title cannot be empty."))
        }
        when (type) {
            TransactionType.EXPENSE -> {
                if (expenseCategory == null) issues.add(localized("Select a category for the expense."))
                if (expenseAmountCents >= 0) issues.add(localized("Amount must be less than 0."))
            }
            TransactionType.INCOME -> {
                val total = incomeRepartition.values.sum()
                if (total <= 0) {
                    issues.add(localized("Income repartition total must be greater than 0."))
                }
                if (total != incomeAmountToSplitCents && incomeAmountToSplitCents > 0) {
                    issues.add(localized("Repartition total does not match the amount to split."))
                }
            }
        }
        return issues
    }

    fun copy(): TransactionGroupDraft = TransactionGroupDraft(title, note, imageAttachmentData, type).also {
        it.expenseCategory = expenseCategory
        it.expenseAmountCents = expenseAmountCents
        it.incomeRepartition = incomeRepartition
        it.incomeAmountToSplitCents = incomeAmountToSplitCents
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TransactionGroupDraft) return false
        return title == other.title &&
            note == other.note &&
            type == other.type &&
            expenseCategory == other.expenseCategory &&
            expenseAmountCents == other.expenseAmountCents &&
            incomeRepartition == other.incomeRepartition &&
            incomeAmountToSplitCents == other.incomeAmountToSplitCents &&
            (imageAttachmentData?.contentEquals(other.imageAttachmentData) ?: (other.imageAttachmentData == null))
    }

    override fun hashCode(): Int = listOf(title, note, type, expenseCategory, expenseAmountCents, incomeRepartition, incomeAmountToSplitCents).hashCode()

    companion object {
        fun from(group: TransactionGroup): TransactionGroupDraft {
            val draft = TransactionGroupDraft(group.title, group.note ?: "", group.imageAttachmentData, group.type)
            when (group.type) {
                TransactionType.EXPENSE -> {
                    val entry = group.entries.firstOrNull()
                    draft.expenseCategory = entry?.category
                    draft.expenseAmountCents = entry?.amountCents ?: 0
                }
                TransactionType.INCOME -> {
                    val repartition = mutableMapOf<BudgetCategory, Int>()
                    var total = 0
                    for (entry in group.entries) {
                        repartition[entry.category] = (repartition[entry.category] ?: 0) + entry.amountCents
                        total += entry.amountCents
                    }
                    draft.incomeRepartition = repartition
                    draft.incomeAmountToSplitCents = max(total, 0)
                }
            }
            return draft
        }
    }
}

class RecurringTransactionRuleDraft private constructor(
    var title: String,
    frequency: RecurrenceFrequency,
    var startDate: Instant,
    var endDate: Instant?,
    var autoConfirm: Boolean,
    var repartition: Map<BudgetCategory, Int>,
    var repartitionTotalCents: Int,
    private val originalStartDate: Instant,
    private val originalEndDate: Instant?,
    private val nextScheduledDate: Instant,
    private val today: Instant
) {
    var frequency: RecurrenceFrequency = frequency
        private set

    var expenseCategory: BudgetCategory?
        get() = repartition.keys.firstOrNull()
        set(value) {
            if (value == null) return
            repartition = mapOf(value to repartitionTotalCents)
        }

    var expenseAmountCents: Int
        get() = repartitionTotalCents
        set(value) {
            val signedAmount = -abs(value)
            repartitionTotalCents = signedAmount
            expenseCategory?.let { repartition = mapOf(it to signedAmount) }
        }

    /** Changing the frequency of a running rule restarts it on its next date. */
    fun setFrequency(newFrequency: RecurrenceFrequency) {
        frequency = newFrequency
        if (startDate < today) {
            startDate = nextScheduledDate
        }
    }

    fun apply(rule: RecurringTransactionRule) {
        rule.title = title
        rule.frequency = frequency
        rule.startDate = startDate
        rule.endDate = endDate
        rule.autoConfirm = autoConfirm
        rule.repartition = repartition
    }

    fun validate(): List<String> {
        val issues = mutableListOf<String>()
        if (title.trim().isEmpty()) {
            issues.add(localized("Title cannot be empty."))
        }
        val total = repartition.values.sum()
        if (total == 0) {
            issues.add(localized("At least one category must have a non-zero amount."))
        }
        if (total != repartitionTotalCents && repartitionTotalCents != 0) {
            issues.add(localized("Repartition total does not match the amount to split."))
        }
        if (startDate != originalStartDate && startDate < today) {
            issues.add(localized("Start date cannot be in the past."))
        }
        val datesChanged = startDate != originalStartDate || endDate != originalEndDate
        val end = endDate
        if (end != null && datesChanged && end <= startDate) {
            issues.add(localized("End date must be at least 7 days after start date."))
        }
        return issues
    }

    companion object {
        fun from(
            rule: RecurringTransactionRule,
            now: Instant = Instant.now(),
            calendar: TrenteCalendar = TrenteCalendar.current
        ): RecurringTransactionRuleDraft {
            val today = calendar.startOfDay(now)
            return RecurringTransactionRuleDraft(
                title = rule.title,
                frequency = rule.frequency,
                startDate = rule.startDate,
                endDate = rule.endDate,
                autoConfirm = rule.autoConfirm,
                repartition = rule.repartition,
                repartitionTotalCents = rule.amountCents,
                originalStartDate = rule.startDate,
                originalEndDate = rule.endDate,
                nextScheduledDate = rule.schedule.firstDate(today, calendar) ?: today,
                today = today
            )
        }
    }
}
