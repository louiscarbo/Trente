package app.trente.core.model

import app.trente.core.EUR
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.SAVINGS_AND_DEBTS
import app.trente.core.model.BudgetCategory.WANTS
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MonthTests {
    private fun makeMonth(startDate: Instant = Instant.now()) = Month(
        startDate = startDate,
        currency = EUR,
        idealBudgetCents = 2000_00,
        idealRepartition = mapOf(NEEDS to 50, WANTS to 30, SAVINGS_AND_DEBTS to 20)
    )

    private fun expense(month: Month, title: String, vararg entries: Pair<BudgetCategory, Int>): TransactionGroup {
        val group = TransactionGroup(title = title, type = TransactionType.EXPENSE, month = month, note = null, imageAttachmentData = null)
        entries.forEach { (category, cents) -> TransactionEntry(amountCents = cents, category = category, group = group) }
        return group
    }

    private fun income(month: Month, title: String, vararg entries: Pair<BudgetCategory, Int>): TransactionGroup {
        val group = TransactionGroup(title = title, type = TransactionType.INCOME, month = month, note = null, imageAttachmentData = null)
        entries.forEach { (category, cents) -> TransactionEntry(amountCents = cents, category = category, group = group) }
        return group
    }

    @Test
    fun spentAmount() {
        val month = makeMonth()
        expense(month, "Groceries", NEEDS to -100_00)
        expense(month, "Rent", NEEDS to -400_00)

        assertEquals(500.0, month.spentAmount(BudgetScope.All))
    }

    @Test
    fun remainingAmount() {
        val month = makeMonth()
        income(month, "Salary", NEEDS to 1000_00)
        expense(month, "Mall", NEEDS to -100_00)
        expense(month, "Rent", NEEDS to -400_00)

        assertEquals(500.0, month.remainingAmount)
    }

    @Test
    fun overSpentTrue() {
        val month = makeMonth()
        expense(month, "Groceries", NEEDS to -100_00)

        assertTrue(month.overSpent)
    }

    @Test
    fun overSpentFalse() {
        val month = makeMonth()
        income(month, "Salary", NEEDS to 2000_00)
        expense(month, "Groceries", NEEDS to -100_00)

        assertFalse(month.overSpent)
    }

    @Test
    fun figuresInScope() {
        val month = makeMonth()
        income(month, "Salary", NEEDS to 600_00, WANTS to 400_00)
        expense(month, "Groceries", NEEDS to -100_00, WANTS to -500_00)

        assertEquals(BudgetFigures(spent = 600.0, income = 1000.0, remaining = 400.0), month.figures(BudgetScope.All))
        assertEquals(BudgetFigures(spent = 100.0, income = 600.0, remaining = 500.0), month.figures(BudgetScope.Category(NEEDS)))
        assertEquals(BudgetFigures(spent = 500.0, income = 400.0, remaining = -100.0), month.figures(BudgetScope.Category(WANTS)))
        assertTrue(month.figures(BudgetScope.Category(WANTS)).isOverspent)
        assertEquals(BudgetFigures(spent = 0.0, income = 0.0, remaining = 0.0), month.figures(BudgetScope.Category(SAVINGS_AND_DEBTS)))
    }

    @Test
    fun endDate1() {
        val calendar = TrenteCalendar.current
        val month = makeMonth(calendar.date(2024, 2, 4))

        assertEquals(calendar.date(2024, 3, 3), month.endDate()) // Leap year
    }

    @Test
    fun endDate2() {
        val calendar = TrenteCalendar.current
        val month = makeMonth(calendar.date(2024, 6, 6))

        assertEquals(calendar.date(2024, 7, 5), month.endDate())
    }

    @Test
    fun endDateOnThirtyFirst() {
        val calendar = TrenteCalendar.current
        val month = makeMonth(calendar.date(2025, 1, 31))
        val expectedEndDate = calendar.date(2025, 2, 27)

        assertEquals(expectedEndDate, month.endDate())
        assertEquals(calendar.plusDays(expectedEndDate, 1), month.dateInterval.end)
    }

    @Test
    fun remainingAmountInCategory() {
        val month = makeMonth()
        income(month, "Salary", NEEDS to 1000_00)
        expense(month, "Mall", NEEDS to -100_00)
        expense(month, "Rent", NEEDS to -400_00)

        assertEquals(500.0, month.remainingAmount(NEEDS))
    }

    @Test
    fun scopedAmounts() {
        val month = makeMonth()
        income(month, "Salary", NEEDS to 1000_00, WANTS to 600_00, SAVINGS_AND_DEBTS to 400_00)
        expense(month, "Spending", NEEDS to -300_00, WANTS to -700_00, SAVINGS_AND_DEBTS to -100_00)

        assertEquals(1100.0, month.spentAmount(BudgetScope.All))
        assertEquals(2000.0, month.incomeAmount(BudgetScope.All))
        assertEquals(900.0, month.remainingAmount(BudgetScope.All))
        assertFalse(month.overSpending(BudgetScope.All))

        assertEquals(100.0, month.spentAmount(BudgetScope.Category(SAVINGS_AND_DEBTS)))
        assertEquals(-100.0, month.remainingAmount(BudgetScope.Category(WANTS)))
        assertTrue(month.overSpending(BudgetScope.Category(WANTS)))
        assertFalse(month.overSpending(BudgetScope.Category(NEEDS)))

        val summedSpent = BudgetCategory.entries.sumOf { month.spentAmount(BudgetScope.Category(it)) }
        assertEquals(month.spentAmount(BudgetScope.All), summedSpent)
    }
}
