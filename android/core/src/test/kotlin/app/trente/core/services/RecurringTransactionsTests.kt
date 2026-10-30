package app.trente.core.services

import app.trente.core.insertMonth
import app.trente.core.makeStore
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.WANTS
import app.trente.core.model.BudgetFigures
import app.trente.core.model.BudgetScope
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import java.time.Duration
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringTransactionsTests {
    private val calendar = TrenteCalendar.current
    private val service = RecurringTransactionService

    private fun day(year: Int, month: Int, day: Int) = calendar.date(year, month, day)

    private fun insertRule(
        title: String,
        startingOn: Instant,
        repartition: Map<BudgetCategory, Int>,
        automatic: Boolean = false,
        store: TrenteStore
    ): RecurringTransactionRule {
        val rule = RecurringTransactionRule(
            title = title,
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = startingOn,
            autoConfirm = automatic,
            repartition = repartition,
            createdAt = startingOn
        )
        store.insert(rule)
        return rule
    }

    @Test
    fun pendingOccurrencesFollowSchedule() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 1, 15), mapOf(NEEDS to -800_00), store = store)
        store.save()

        val occurrences = service.pendingOccurrences(listOf(rule), april)

        assertEquals(listOf(day(2025, 4, 15)), occurrences.map { it.date })
        assertEquals(-800_00, occurrences.first().amountCents)
    }

    @Test
    fun confirmIncome() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Salary", day(2025, 4, 1), mapOf(NEEDS to 1500_00, WANTS to 500_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.confirm(occurrence, store)

        val group = april.transactionGroups.first()
        assertEquals(1, april.transactionGroups.size)
        assertEquals(TransactionType.INCOME, group.type)
        assertEquals(2, group.entries.size)
        assertEquals(2000_00, group.totalAmountCents)
        assertTrue(group.recurringRule === rule)
        assertEquals(day(2025, 4, 1), group.recurringOccurrenceDate)
        assertTrue(service.pendingOccurrences(listOf(rule), april).isEmpty())
    }

    @Test
    fun confirmExpense() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.confirm(occurrence, store)

        val group = april.transactionGroups.first()
        assertEquals(TransactionType.EXPENSE, group.type)
        assertEquals(listOf(-800_00), group.entries.map { it.amountCents })
        assertEquals(NEEDS, group.entries.first().category)
    }

    @Test
    fun confirmTwice() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Salary", day(2025, 4, 1), mapOf(NEEDS to 1000_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.confirm(occurrence, store)
        service.confirm(occurrence, store)

        assertEquals(1, april.transactionGroups.size)
    }

    @Test
    fun deletingConfirmedTransactionRestoresOccurrence() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()
        service.confirm(occurrence, store)
        val group = april.transactionGroups.first()

        TransactionService.delete(group, store)
        store.save()

        assertEquals(listOf(day(2025, 4, 2)), service.pendingOccurrences(listOf(rule), april).map { it.date })
    }

    @Test
    fun deletingRuleKeepsTransactions() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()
        service.confirm(occurrence, store)

        service.delete(rule, store)
        store.save()

        val groups = store.transactionGroups
        assertEquals(1, groups.size)
        assertNull(groups.first().recurringRule)
        assertTrue(store.rules.isEmpty())
    }

    @Test
    fun movingPaymentDayKeepsMonthSettled() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()
        service.confirm(occurrence, store)

        rule.startDate = day(2025, 4, 20)
        store.save()

        assertTrue(service.pendingOccurrences(listOf(rule), april).isEmpty())
    }

    @Test
    fun confirmingOneMonthLeavesOthersPending() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val may = insertMonth(2025, 5, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.confirm(occurrence, store)

        assertEquals(listOf(day(2025, 5, 2)), service.pendingOccurrences(listOf(rule), may).map { it.date })
    }

    @Test
    fun pendingOccurrencesAreSorted() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val netflix = insertRule("Netflix", day(2025, 1, 22), mapOf(WANTS to -13_99), store = store)
        val rent = insertRule("Rent", day(2025, 1, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()

        val titles = service.pendingOccurrences(listOf(netflix, rent), april).map { it.rule.title }

        assertEquals(listOf("Rent", "Netflix"), titles)
    }

    @Test
    fun skippingHidesOnlyThatMonth() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val may = insertMonth(2025, 5, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.skip(occurrence, store)

        assertTrue(service.pendingOccurrences(listOf(rule), april).isEmpty())
        assertEquals(listOf(day(2025, 5, 2)), service.pendingOccurrences(listOf(rule), may).map { it.date })
        assertTrue(april.transactionGroups.isEmpty())
    }

    @Test
    fun skippingTwiceStoresOnce() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.skip(occurrence, store)
        service.skip(occurrence, store)

        assertEquals(1, rule.skippedOccurrenceDates.size)
    }

    @Test
    fun stoppingKeepsTodayAndDropsFuture() {
        val store = makeStore()
        val today = calendar.startOfDay(Instant.now())
        val thisMonthDate = calendar.localDate(today)
        val thisMonth = insertMonth(thisMonthDate.year, thisMonthDate.monthValue, store)
        val nextMonthDate = calendar.localDate(calendar.plusMonths(thisMonth.startDate, 1))
        val nextMonth = insertMonth(nextMonthDate.year, nextMonthDate.monthValue, store)
        val rule = insertRule("Gym", today, mapOf(WANTS to -29_00), store = store)
        store.save()
        assertFalse(rule.hasEnded())

        service.stop(rule, store)

        assertTrue(rule.hasEnded())
        assertEquals(listOf(today), service.pendingOccurrences(listOf(rule), thisMonth).map { it.date })
        assertTrue(service.pendingOccurrences(listOf(rule), nextMonth).isEmpty())
    }

    @Test
    fun manualConfirmIsDatedNow() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrence = service.pendingOccurrences(listOf(rule), april).first()

        service.confirm(occurrence, store)

        val group = april.transactionGroups.first()
        assertTrue(Duration.between(group.addedDate, Instant.now()).abs().seconds < 60)
    }

    @Test
    fun catchUpConfirmsOnDueDate() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        store.save()

        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        assertEquals(1, confirmedCount)
        val group = april.transactionGroups.first()
        assertEquals(day(2025, 4, 2), group.addedDate)
        assertEquals(day(2025, 4, 2), group.recurringOccurrenceDate)
    }

    @Test
    fun catchUpSkipsManualFutureAndSkipped() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val netflix = insertRule("Netflix", day(2025, 4, 5), mapOf(WANTS to -13_99), store = store)
        val gym = insertRule("Gym", day(2025, 4, 28), mapOf(WANTS to -29_00), automatic = true, store = store)
        val rent = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        store.save()
        service.skip(rent.pendingOccurrences(april).first(), store)

        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        assertEquals(0, confirmedCount)
        assertTrue(april.transactionGroups.isEmpty())
        assertEquals(listOf("Netflix", "Gym"), service.pendingOccurrences(listOf(netflix, gym, rent), april).map { it.rule.title })
    }

    @Test
    fun catchUpTwiceConfirmsOnce() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        store.save()

        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)
        val secondCount = service.confirmDueOccurrences(store, now = day(2025, 4, 11), isAutomaticUnlocked = true)

        assertEquals(0, secondCount)
        assertEquals(1, april.transactionGroups.size)
    }

    @Test
    fun deletedAutomaticTransactionStaysPending() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        store.save()
        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)
        val group = april.transactionGroups.first()

        TransactionService.delete(group, store)
        store.save()
        val secondCount = service.confirmDueOccurrences(store, now = day(2025, 4, 11), isAutomaticUnlocked = true)

        assertEquals(0, secondCount)
        assertTrue(store.transactionGroups.isEmpty())
        assertEquals(listOf(day(2025, 4, 2)), service.pendingOccurrences(listOf(rule), april).map { it.date })
    }

    @Test
    fun figuresIncludeAutomaticOccurrences() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val salary = insertRule("Salary", day(2025, 4, 1), mapOf(NEEDS to 1000_00, WANTS to 500_00), store = store)
        val rent = insertRule("Rent", day(2025, 4, 2), mapOf(NEEDS to -800_00), store = store)
        store.save()
        val occurrences = service.pendingOccurrences(listOf(salary, rent), april)

        val overall = april.figures(BudgetScope.All, occurrences)
        val needs = april.figures(BudgetScope.Category(NEEDS), occurrences)
        val wants = april.figures(BudgetScope.Category(WANTS), occurrences)

        assertEquals(BudgetFigures(spent = 800.0, income = 1500.0, remaining = 700.0), overall)
        assertEquals(BudgetFigures(spent = 800.0, income = 1000.0, remaining = 200.0), needs)
        assertEquals(BudgetFigures(spent = 0.0, income = 500.0, remaining = 500.0), wants)
    }

    @Test
    fun catchUpSavesOnce() {
        val store = makeStore()
        for (month in 1..4) {
            insertMonth(2025, month, store)
        }
        insertRule("Rent", day(2025, 1, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        store.save()
        val savesBefore = store.saveCount

        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        assertEquals(4, confirmedCount)
        assertEquals(1, store.saveCount - savesBefore)
        assertEquals(4, store.transactionGroups.size)
    }

    @Test
    fun catchUpWithNothingDueDoesNotSave() {
        val store = makeStore()
        insertMonth(2025, 4, store)
        insertRule("Gym", day(2025, 4, 28), mapOf(WANTS to -29_00), automatic = true, store = store)
        store.save()
        val savesBefore = store.saveCount

        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        assertEquals(0, store.saveCount - savesBefore)
    }

    @Test
    fun catchUpResumesAfterCheckpoint() {
        val store = makeStore()
        for (month in 1..4) {
            insertMonth(2025, month, store)
        }
        val rule = insertRule("Rent", day(2025, 1, 2), mapOf(NEEDS to -800_00), automatic = true, store = store)
        rule.lastAutoConfirmedDate = day(2025, 2, 2)
        store.save()

        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        val confirmedDates = store.transactionGroups.mapNotNull { it.recurringOccurrenceDate }.sorted()
        assertEquals(2, confirmedCount)
        assertEquals(listOf(day(2025, 3, 2), day(2025, 4, 2)), confirmedDates)
        assertEquals(day(2025, 4, 2), rule.lastAutoConfirmedDate)
        assertNotNull(rule.lastAutoConfirmedDate)
    }
}
