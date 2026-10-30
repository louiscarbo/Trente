package app.trente.core.model

import app.trente.core.support.localized

/** The three 50/30/20 categories. `rawValue` is what the database and the CSV export store, matching the iOS app. */
enum class BudgetCategory(val rawValue: String) {
    NEEDS("needs"),
    WANTS("wants"),
    SAVINGS_AND_DEBTS("savingsAndDebts");

    val displayName: String
        get() = when (this) {
            NEEDS -> localized("Needs")
            WANTS -> localized("Wants")
            SAVINGS_AND_DEBTS -> localized("Savings and Debts")
        }

    val shortName: String
        get() = when (this) {
            NEEDS -> localized("Needs")
            WANTS -> localized("Wants")
            SAVINGS_AND_DEBTS -> localized("Savings")
        }

    val shortExamples: String
        get() = when (this) {
            NEEDS -> localized("Rent, groceries, bills...")
            WANTS -> localized("Dining out, entertainment...")
            SAVINGS_AND_DEBTS -> localized("Savings, debt, retirement...")
        }

    companion object {
        fun fromRawValue(rawValue: String): BudgetCategory? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

sealed class BudgetScope {
    data object All : BudgetScope()
    data class Category(val category: BudgetCategory) : BudgetScope()
}

data class BudgetFigures(val spent: Double, val income: Double, val remaining: Double) {
    val isOverspent: Boolean get() = remaining < 0

    companion object {
        val zero = BudgetFigures(0.0, 0.0, 0.0)
    }
}

enum class TransactionType(val rawValue: String) {
    EXPENSE("expense"),
    INCOME("income");

    companion object {
        fun fromRawValue(rawValue: String): TransactionType? = entries.firstOrNull { it.rawValue == rawValue }
    }
}

enum class RecurrenceFrequency(val rawValue: String) {
    WEEKLY("weekly"),
    MONTHLY("monthly"),
    YEARLY("yearly");

    val displayName: String
        get() = when (this) {
            WEEKLY -> localized("Weekly")
            MONTHLY -> localized("Monthly")
            YEARLY -> localized("Yearly")
        }

    companion object {
        fun fromRawValue(rawValue: String): RecurrenceFrequency? = entries.firstOrNull { it.rawValue == rawValue }
    }
}
