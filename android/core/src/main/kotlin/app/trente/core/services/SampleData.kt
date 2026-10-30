package app.trente.core.services

import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.SAVINGS_AND_DEBTS
import app.trente.core.model.BudgetCategory.WANTS
import app.trente.core.model.Currencies
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import java.time.Instant

data class SampleTransaction(
    val title: String,
    val day: Int,
    val entries: Map<BudgetCategory, Int>,
    val note: String? = null
) {
    companion object {
        fun expense(title: String, day: Int, category: BudgetCategory, amountCents: Int) =
            SampleTransaction(title, day, mapOf(category to -amountCents))
    }
}

/** Four months of plausible data for the debug build, previews and screenshots. */
object SampleData {
    const val MONTH_COUNT = 4
    const val CURRENCY_CODE = "EUR"
    const val IDEAL_BUDGET_CENTS = 2500_00
    val idealRepartition: Map<BudgetCategory, Int> = mapOf(NEEDS to 1250_00, WANTS to 750_00, SAVINGS_AND_DEBTS to 500_00)

    val recurring: List<SampleTransaction> = listOf(
        SampleTransaction(
            title = "Salary",
            day = 1,
            entries = mapOf(NEEDS to 1250_00, WANTS to 750_00, SAVINGS_AND_DEBTS to 500_00),
            note = "Monthly paycheck from Trente Inc."
        ),
        SampleTransaction.expense("Rent", 2, NEEDS, 700_00),
        SampleTransaction.expense("Livret A", 3, SAVINGS_AND_DEBTS, 400_00),
        SampleTransaction.expense("Phone plan", 5, NEEDS, 19_99),
        SampleTransaction.expense("Netflix", 15, WANTS, 13_49),
        SampleTransaction.expense("Gym", 28, WANTS, 29_00)
    )

    val oneOffsByMonthsAgo: List<List<SampleTransaction>> = listOf(
        listOf(
            SampleTransaction.expense("Supermarket", 3, NEEDS, 84_20),
            SampleTransaction.expense("Bakery", 4, WANTS, 6_80),
            SampleTransaction.expense("Pharmacy", 6, NEEDS, 18_50),
            SampleTransaction.expense("Supermarket", 10, NEEDS, 92_35),
            SampleTransaction.expense("Restaurant", 11, WANTS, 46_00),
            SampleTransaction.expense("Train ticket", 12, NEEDS, 34_00),
            SampleTransaction.expense("Cinema", 14, WANTS, 23_50),
            SampleTransaction.expense("Supermarket", 17, NEEDS, 78_90),
            SampleTransaction.expense("Clothes", 19, WANTS, 64_99),
            SampleTransaction.expense("Electricity", 20, NEEDS, 58_40),
            SampleTransaction.expense("Supermarket", 24, NEEDS, 88_10),
            SampleTransaction.expense("Birthday gift", 26, WANTS, 35_00)
        ),
        listOf(
            SampleTransaction.expense("Supermarket", 4, NEEDS, 91_60),
            SampleTransaction.expense("Restaurant", 6, WANTS, 52_30),
            SampleTransaction.expense("Supermarket", 11, NEEDS, 85_75),
            SampleTransaction.expense("Pharmacy", 13, NEEDS, 12_90),
            SampleTransaction.expense("Concert tickets", 14, WANTS, 78_00),
            SampleTransaction.expense("Supermarket", 18, NEEDS, 96_40),
            SampleTransaction.expense("Electricity", 20, NEEDS, 61_20),
            SampleTransaction.expense("Clothes", 22, WANTS, 129_99),
            SampleTransaction.expense("Train ticket", 23, NEEDS, 41_00),
            SampleTransaction.expense("Supermarket", 25, NEEDS, 73_85),
            SampleTransaction.expense("Restaurant", 27, WANTS, 38_50)
        ),
        listOf(
            SampleTransaction.expense("Supermarket", 3, NEEDS, 102_15),
            SampleTransaction.expense("Holiday booking", 5, WANTS, 240_00),
            SampleTransaction.expense("Supermarket", 9, NEEDS, 88_60),
            SampleTransaction.expense("Restaurant", 12, WANTS, 67_80),
            SampleTransaction.expense("Pharmacy", 14, NEEDS, 21_40),
            SampleTransaction.expense("Supermarket", 17, NEEDS, 95_05),
            SampleTransaction.expense("Electricity", 20, NEEDS, 49_70),
            SampleTransaction.expense("Restaurant", 22, WANTS, 71_20),
            SampleTransaction.expense("Supermarket", 24, NEEDS, 81_30),
            SampleTransaction.expense("Birthday gift", 26, WANTS, 45_00),
            SampleTransaction.expense("Car repair", 27, NEEDS, 180_00)
        ),
        listOf(
            SampleTransaction.expense("Supermarket", 2, NEEDS, 87_45),
            SampleTransaction.expense("Summer sale", 6, WANTS, 149_90),
            SampleTransaction.expense("Supermarket", 9, NEEDS, 79_10),
            SampleTransaction.expense("Restaurant", 13, WANTS, 54_00),
            SampleTransaction.expense("Train ticket", 14, NEEDS, 29_50),
            SampleTransaction.expense("Supermarket", 16, NEEDS, 90_25),
            SampleTransaction.expense("Electricity", 20, NEEDS, 44_80),
            SampleTransaction.expense("Cinema", 21, WANTS, 19_00),
            SampleTransaction.expense("Supermarket", 23, NEEDS, 83_60),
            SampleTransaction.expense("Restaurant", 27, WANTS, 62_40)
        )
    )

    fun startDate(monthsAgo: Int, now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): Instant {
        val currentMonthStart = calendar.instant(calendar.localDate(now).withDayOfMonth(1))
        return calendar.plusMonths(currentMonthStart, -monthsAgo.toLong())
    }

    fun date(day: Int, monthStart: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Instant =
        calendar.withTime(calendar.plusDays(monthStart, (day - 1).toLong()), 12, 0)

    fun transactions(monthsAgo: Int, now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): List<SampleTransaction> {
        val all = recurring + oneOffsByMonthsAgo[monthsAgo]
        if (monthsAgo != 0) return all
        val monthStart = startDate(monthsAgo, now, calendar)
        return all.filter { date(it.day, monthStart, calendar) <= now }
    }

    fun group(transaction: SampleTransaction, month: Month, calendar: TrenteCalendar = TrenteCalendar.current): TransactionGroup {
        val isIncome = transaction.entries.values.any { it > 0 }
        val group = TransactionGroup(
            title = transaction.title,
            type = if (isIncome) TransactionType.INCOME else TransactionType.EXPENSE,
            month = month,
            note = transaction.note,
            imageAttachmentData = null,
            addedDate = date(transaction.day, month.startDate, calendar)
        )
        for (category in BudgetCategory.entries) {
            transaction.entries[category]?.let { TransactionEntry(it, category, group) }
        }
        return group
    }

    fun month(monthsAgo: Int, now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): Month {
        val month = Month(
            startDate = startDate(monthsAgo, now, calendar),
            currency = Currencies.currency(CURRENCY_CODE)!!,
            idealBudgetCents = IDEAL_BUDGET_CENTS,
            idealRepartition = idealRepartition
        )
        transactions(monthsAgo, now, calendar).forEach { group(it, month, calendar) }
        return month
    }

    fun rules(now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current): List<RecurringTransactionRule> =
        recurring.map { transaction ->
            val startDate = date(transaction.day, startDate(MONTH_COUNT - 1, now, calendar), calendar)
            RecurringTransactionRule(
                title = transaction.title,
                frequency = RecurrenceFrequency.MONTHLY,
                startDate = startDate,
                autoConfirm = true,
                repartition = transaction.entries,
                createdAt = startDate
            )
        }

    /** Fills an empty store with the sample months and rules, linked like the iOS `DataProvider`. */
    fun populate(store: TrenteStore, now: Instant = Instant.now(), calendar: TrenteCalendar = TrenteCalendar.current) {
        val rules = rules(now, calendar)
        rules.forEach(store::insert)
        for (monthsAgo in 0 until MONTH_COUNT) {
            val month = month(monthsAgo, now, calendar)
            store.insert(month)
            for (group in month.transactionGroups) {
                val rule = rules.firstOrNull { it.title == group.title } ?: continue
                group.recurringRule = rule
                group.recurringOccurrenceDate = group.addedDate
            }
        }
        store.save()
    }
}
