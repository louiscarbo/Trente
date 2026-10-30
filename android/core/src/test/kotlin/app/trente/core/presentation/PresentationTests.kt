package app.trente.core.presentation

import app.trente.core.EUR
import app.trente.core.FakeNotificationCenter
import app.trente.core.insertMonth
import app.trente.core.makeStore
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.SAVINGS_AND_DEBTS
import app.trente.core.model.BudgetCategory.WANTS
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.services.ImageAttachmentLoader
import app.trente.core.services.SampleData
import app.trente.core.services.TransactionCreationRequest
import app.trente.core.model.dayOfMonthString
import app.trente.core.support.DateText
import app.trente.core.support.NotificationPermissionService
import app.trente.core.support.NotificationPermissionStatus
import java.time.Instant
import java.util.Locale
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.runTest
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

private val calendar = TrenteCalendar.current

private fun makeMonth(startDate: Instant = Instant.now(), idealBudgetCents: Int = 2000_00) = Month(
    startDate = startDate,
    currency = EUR,
    idealBudgetCents = idealBudgetCents,
    idealRepartition = mapOf(NEEDS to 50, WANTS to 30, SAVINGS_AND_DEBTS to 20)
)

class RecurringTransactionRuleDescriptionTests {
    @Test
    fun yearlyDescriptionUsesDayOfMonth() {
        val startDate = calendar.date(2026, 10, 27)
        val rule = RecurringTransactionRule(
            title = "Insurance",
            frequency = RecurrenceFrequency.YEARLY,
            startDate = startDate,
            repartition = mapOf(NEEDS to -300_00),
            createdAt = startDate
        )

        assertTrue(rule.frequencyDescription().contains("27"))
        assertTrue(rule.frequencyDescription().contains(DateText.monthWide(calendar.localDate(startDate))))
    }

    @Test
    fun monthlyDayFormatting() {
        val cases = listOf(
            "en" to "15th", "en-GB" to "15th", "de" to "15.", "fr" to "15", "es" to "15",
            "es-419" to "15", "it" to "15", "ko" to "15", "pt-BR" to "15", "pt-PT" to "15"
        )
        for ((localization, expected) in cases) {
            assertEquals(expected, 15.dayOfMonthString(localization), localization)
        }
    }
}

class TransactionCreationRequestTests {
    @Test
    fun switchingToIncome() {
        val request = TransactionCreationRequest()
        request.amountCents = -25_00
        request.selectedCategory = WANTS

        request.type = TransactionType.INCOME

        assertEquals(25_00, request.amountCents)
        assertNull(request.selectedCategory)
    }

    @Test
    fun switchingBackToExpense() {
        val request = TransactionCreationRequest()
        request.type = TransactionType.INCOME
        request.amountCents = 25_00

        request.type = TransactionType.EXPENSE

        assertEquals(-25_00, request.amountCents)
    }

    @Test
    fun typedAmountTakesTheSign() {
        for (type in TransactionType.entries) {
            val request = TransactionCreationRequest()
            request.type = type

            request.amountCents = 12_00

            assertEquals(if (type == TransactionType.INCOME) 12_00 else -12_00, request.amountCents)
        }
    }
}

class SampleDataTests {
    @Test
    fun transactionsFallInsideTheirMonth() {
        for (monthsAgo in 0 until SampleData.MONTH_COUNT) {
            val month = SampleData.month(monthsAgo)

            for (group in month.transactionGroups) {
                assertTrue(group.addedDate >= month.startDate)
                assertTrue(group.addedDate <= month.endDate().plusSeconds(24 * 60 * 60))
            }
        }
    }

    @Test
    fun currentMonthHasNoFutureTransactions() {
        val month = SampleData.month(0)

        assertTrue(month.transactionGroups.all { it.addedDate <= Instant.now() })
    }

    @Test
    fun transactionsAreSpreadOverSeveralDays() {
        val month = SampleData.month(1)
        val distinctDays = month.transactionGroups.map { calendar.localDate(it.addedDate).dayOfMonth }.toSet()

        assertTrue(distinctDays.size > 5)
    }

    @Test
    fun groupTypesMatchEntrySigns() {
        val month = SampleData.month(1)

        for (group in month.transactionGroups) {
            val allPositive = group.entries.all { it.amountCents > 0 }
            assertEquals(group.type == TransactionType.INCOME, allPositive)
        }
    }
}

class DailySpendingTests {
    private fun date(year: Int, month: Int, day: Int, hour: Int = 12) = calendar.date(year, month, day, hour)

    private fun month(startingOn: Instant = calendar.date(2026, 3, 1)) = makeMonth(startingOn)

    private fun addExpense(month: Month, cents: Int, category: BudgetCategory, on: Instant, type: TransactionType = TransactionType.EXPENSE) {
        val group = TransactionGroup(title = "Test", type = type, month = month, note = null, imageAttachmentData = null, addedDate = on)
        TransactionEntry(cents, category, group)
    }

    @Test
    fun groupsByDayAndCategory() {
        val month = month()
        addExpense(month, -1000, NEEDS, date(2026, 3, 5, 9))
        addExpense(month, -500, WANTS, date(2026, 3, 5, 18))
        addExpense(month, -250, NEEDS, date(2026, 3, 6))

        val spending = DailySpending(month, now = date(2026, 3, 10), calendar = calendar)

        assertEquals(2, spending.days.size)
        assertEquals(10.0, spending.days[0].amounts[NEEDS])
        assertEquals(5.0, spending.days[0].amounts[WANTS])
        assertEquals(15.0, spending.days[0].total)
        assertEquals(2.5, spending.days[1].total)
    }

    @Test
    fun ignoresIncome() {
        val month = month()
        addExpense(month, 5000, NEEDS, date(2026, 3, 5), TransactionType.INCOME)

        assertTrue(DailySpending(month, now = date(2026, 3, 10), calendar = calendar).days.isEmpty())
    }

    @Test
    fun dropsGroupsOutsideMonth() {
        val month = month()
        addExpense(month, -1000, NEEDS, date(2026, 2, 28))
        addExpense(month, -1000, NEEDS, date(2026, 3, 1, 0))
        addExpense(month, -1000, NEEDS, date(2026, 3, 31, 23))
        addExpense(month, -1000, NEEDS, date(2026, 4, 1))

        val spending = DailySpending(month, now = date(2026, 3, 10), calendar = calendar)

        assertEquals(2, spending.days.size)
        assertEquals(10.0, spending.maxTotal(null))
    }

    @Test
    fun defaultWeekStartCurrentMonth() {
        val spending = DailySpending(month(), now = date(2026, 3, 20), calendar = calendar)

        assertEquals(calendar.startOfDay(date(2026, 3, 14)), spending.defaultWeekStart)
        assertEquals(calendar.startOfDay(date(2026, 3, 20)), spending.today)
    }

    @Test
    fun defaultWeekStartClampedToMonthStart() {
        val spending = DailySpending(month(), now = date(2026, 3, 3), calendar = calendar)

        assertEquals(calendar.startOfDay(date(2026, 3, 1)), spending.defaultWeekStart)
    }

    @Test
    fun defaultWeekStartPastMonth() {
        val spending = DailySpending(month(), now = date(2026, 6, 15), calendar = calendar)

        assertNull(spending.today)
        assertEquals(calendar.startOfDay(date(2026, 3, 25)), spending.defaultWeekStart)
    }

    @Test
    fun weekWindow() {
        val spending = DailySpending(month(), now = date(2026, 3, 20), calendar = calendar)

        val window = spending.weekWindow(date(2026, 3, 10, 15))

        assertEquals(calendar.startOfDay(date(2026, 3, 10)), window.start)
        assertEquals(calendar.startOfDay(date(2026, 3, 16)), window.endInclusive)
    }

    @Test
    fun maxTotalInWindow() {
        val month = month()
        addExpense(month, -9000, NEEDS, date(2026, 3, 2))
        addExpense(month, -1000, NEEDS, date(2026, 3, 20))

        val spending = DailySpending(month, now = date(2026, 3, 25), calendar = calendar)

        assertEquals(10.0, spending.maxTotal(date(2026, 3, 18)))
        assertEquals(90.0, spending.maxTotal(null))
    }

    @Test
    fun daysInMonth() {
        assertEquals(31, DailySpending(month(), now = date(2026, 3, 1), calendar = calendar).daysInMonth)
        assertEquals(28, DailySpending(month(date(2026, 2, 1)), now = date(2026, 3, 1), calendar = calendar).daysInMonth)
    }

    @Test
    fun slices() {
        val days = listOf(DailySpend(date(2026, 3, 1), mapOf(NEEDS to 2.0, WANTS to 1.0)))

        val slices = CategorySlice.slices(days)

        assertEquals(listOf(NEEDS, WANTS), slices.map { it.category })
        assertEquals(listOf(67, 33), slices.map { it.percent })
    }

    @Test
    fun slicesOfSubUnitTotal() {
        val slices = CategorySlice.slices(listOf(DailySpend(date(2026, 3, 1), mapOf(NEEDS to 0.5))))

        assertEquals(1, slices.size)
        assertEquals(1.0, slices[0].share)
        assertEquals(100, slices[0].percent)
    }

    @Test
    fun noSlices() {
        assertTrue(CategorySlice.slices(emptyList()).isEmpty())
    }
}

class BudgetRingsTests {
    private val income = mapOf(NEEDS to 1500.0, WANTS to 900.0, SAVINGS_AND_DEBTS to 600.0)

    private fun rings(needs: Double, wants: Double, savings: Double) =
        BudgetRings(spent = mapOf(NEEDS to needs, WANTS to wants, SAVINGS_AND_DEBTS to savings), income = income)

    private fun share(kind: BudgetRings.SliceKind, slices: List<BudgetRings.Slice>) = slices.firstOrNull { it.kind == kind }?.share ?: -1.0
    private fun total(slices: List<BudgetRings.Slice>) = slices.sumOf { it.share }

    @Test
    fun splitSegments() {
        val segments = rings(1100.0, 620.0, 400.0).segments(BudgetRings.Lens.SPLIT)

        assertTrue(abs(share(BudgetRings.SliceKind.Category(NEEDS), segments) - 1100.0 / 2120) < 0.0001)
        assertTrue(abs(share(BudgetRings.SliceKind.Category(WANTS), segments) - 620.0 / 2120) < 0.0001)
        assertEquals(0.0, share(BudgetRings.SliceKind.Remaining, segments))
        assertEquals(0.0, share(BudgetRings.SliceKind.Overspent, segments))
        assertTrue(abs(total(segments) - 1) < 0.0001)
    }

    @Test
    fun splitPlan() {
        val plan = rings(1100.0, 620.0, 400.0).plan(BudgetRings.Lens.SPLIT)

        assertEquals(0.5, share(BudgetRings.SliceKind.Category(NEEDS), plan))
        assertEquals(0.3, share(BudgetRings.SliceKind.Category(WANTS), plan))
        assertTrue(abs(share(BudgetRings.SliceKind.Category(SAVINGS_AND_DEBTS), plan) - 0.2) < 0.0001)
    }

    @Test
    fun leftToSpendUnderIncome() {
        val budget = rings(1100.0, 620.0, 400.0)
        val segments = budget.segments(BudgetRings.Lens.LEFT_TO_SPEND)
        val plan = budget.plan(BudgetRings.Lens.LEFT_TO_SPEND)

        assertTrue(abs(share(BudgetRings.SliceKind.Category(NEEDS), segments) - 1100.0 / 3000) < 0.0001)
        assertTrue(abs(share(BudgetRings.SliceKind.Remaining, segments) - 880.0 / 3000) < 0.0001)
        assertEquals(0.0, share(BudgetRings.SliceKind.Overspent, segments))
        assertTrue(abs(total(segments) - 1) < 0.0001)
        assertTrue(abs(share(BudgetRings.SliceKind.Remaining, plan) - 880.0 / 3000) < 0.0001)
        assertTrue(abs(total(plan) - 1) < 0.0001)
    }

    @Test
    fun leftToSpendPastIncome() {
        val segments = rings(1600.0, 1200.0, 500.0).segments(BudgetRings.Lens.LEFT_TO_SPEND)

        assertTrue(abs(share(BudgetRings.SliceKind.Overspent, segments) - 300.0 / 3300) < 0.0001)
        assertEquals(0.0, share(BudgetRings.SliceKind.Remaining, segments))
        assertTrue(abs(share(BudgetRings.SliceKind.Category(NEEDS), segments) - 1600.0 / 3300 * 3000 / 3300) < 0.0001)
        assertTrue(abs(total(segments) - 1) < 0.0001)
        assertEquals(1, segments.count { it.kind == BudgetRings.SliceKind.Category(NEEDS) })
    }

    @Test
    fun centerShare() {
        assertTrue(abs((rings(1100.0, 620.0, 400.0).centerShare(BudgetRings.Lens.SPLIT) ?: 0.0) - 2120.0 / 3000) < 0.0001)
        assertTrue(abs((rings(1100.0, 620.0, 400.0).centerShare(BudgetRings.Lens.LEFT_TO_SPEND) ?: 0.0) - 880.0 / 3000) < 0.0001)
        assertTrue(abs((rings(1600.0, 1200.0, 500.0).centerShare(BudgetRings.Lens.LEFT_TO_SPEND) ?: 0.0) - 0.1) < 0.0001)
        assertNull(BudgetRings(spent = mapOf(NEEDS to 10.0), income = emptyMap()).centerShare(BudgetRings.Lens.SPLIT))
    }

    @Test
    fun emptyMonth() {
        val budget = rings(0.0, 0.0, 0.0)

        assertFalse(budget.hasSpending)
        assertEquals(0.0, total(budget.segments(BudgetRings.Lens.SPLIT)))
        assertEquals(0.0, budget.centerShare(BudgetRings.Lens.SPLIT))
    }

    @Test
    fun readsMonth() {
        val month = makeMonth(calendar.date(2026, 3, 1), idealBudgetCents = 3000_00)
        val salary = TransactionGroup("Salary", TransactionType.INCOME, month, null, null, addedDate = month.startDate)
        TransactionEntry(1500_00, NEEDS, salary)
        TransactionEntry(900_00, WANTS, salary)
        TransactionEntry(600_00, SAVINGS_AND_DEBTS, salary)
        val groceries = TransactionGroup("Groceries", TransactionType.EXPENSE, month, null, null, addedDate = month.startDate)
        TransactionEntry(-120_50, NEEDS, groceries)

        val budget = BudgetRings(month)

        assertEquals(3000.0, budget.totalIncome)
        assertEquals(120.5, budget.spent[NEEDS])
        assertEquals(0.0, budget.spent[WANTS])
        assertEquals(900.0, budget.income[WANTS])
    }
}

class RepartitionSplitTests {
    @Test
    fun decreaseRemovesCentsFirst() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 12_30))

        split.decrease(NEEDS)
        assertEquals(12_00, split.amount(NEEDS))

        split.decrease(NEEDS)
        assertEquals(11_00, split.amount(NEEDS))
    }

    @Test
    fun decreaseOnZeroDoesNothing() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 0))

        split.decrease(NEEDS)

        assertEquals(RepartitionSplit(20_00, mapOf(NEEDS to 0)), split)
    }

    @Test
    fun decreaseOnUnsetCategoryStoresZero() {
        val split = RepartitionSplit(20_00, emptyMap())

        split.decrease(WANTS)

        assertEquals(mapOf(WANTS to 0), split.values)
    }

    @Test
    fun decreaseCentsOnlyStopsAtZero() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 40))

        split.decrease(NEEDS)

        assertEquals(0, split.amount(NEEDS))
    }

    @Test
    fun increaseAddsLastCents() {
        val split = RepartitionSplit(60_30, mapOf(NEEDS to 60_00))

        split.increase(NEEDS)

        assertEquals(60_30, split.amount(NEEDS))
        assertEquals(0, split.remaining)
    }

    @Test
    fun increaseAddsOneUnit() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 15_00))

        split.increase(NEEDS)

        assertEquals(16_00, split.amount(NEEDS))
    }

    @Test
    fun increaseWithNothingLeftDoesNothing() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 15_00, WANTS to 5_00))

        split.increase(NEEDS)

        assertEquals(RepartitionSplit(20_00, mapOf(NEEDS to 15_00, WANTS to 5_00)), split)
    }

    @Test
    fun setRoundsDown() {
        val split = RepartitionSplit(20_00, emptyMap())

        split.set(NEEDS, 15_70)

        assertEquals(15_00, split.amount(NEEDS))
    }

    @Test
    fun setBeyondRemainingIsCapped() {
        val split = RepartitionSplit(20_00, mapOf(WANTS to 4_50))

        split.set(NEEDS, 30_00)

        assertEquals(15_00, split.amount(NEEDS))
        assertEquals(50, split.remaining)
    }

    @Test
    fun setLowerDropsCents() {
        val split = RepartitionSplit(20_00, mapOf(NEEDS to 12_30))

        split.set(NEEDS, 12_30)

        assertEquals(12_00, split.amount(NEEDS))
    }

    @Test
    fun dragToEndKeepsCents() {
        assertEquals(60_00, RepartitionSplit(60_30, emptyMap()).value(forDragFraction = 1.0, of = NEEDS))
    }

    @Test
    fun dragRoundsDown() {
        val split = RepartitionSplit(60_30, emptyMap())

        assertEquals(30_00, split.value(forDragFraction = 0.5, of = NEEDS))
        assertEquals(59_00, split.value(forDragFraction = 0.99, of = NEEDS))
    }

    @Test
    fun dragOutsideIsClamped() {
        val split = RepartitionSplit(60_30, emptyMap())

        assertEquals(0, split.value(forDragFraction = -0.2, of = NEEDS))
        assertEquals(60_00, split.value(forDragFraction = 1.5, of = NEEDS))
    }

    @Test
    fun dragIsCappedAtMaxValue() {
        val split = RepartitionSplit(60_30, mapOf(WANTS to 40_00))

        val draggedValue = split.value(forDragFraction = 1.0, of = NEEDS)
        assertEquals(20_30, draggedValue)

        split.set(NEEDS, draggedValue)
        assertEquals(20_00, split.amount(NEEDS))
    }

    @Test
    fun remainingMatchesValues() {
        val split = RepartitionSplit(60_30, emptyMap())
        val steps: List<(RepartitionSplit) -> Unit> = listOf(
            { it.set(NEEDS, it.value(forDragFraction = 0.5, of = NEEDS)) },
            { it.increase(WANTS) },
            { it.set(SAVINGS_AND_DEBTS, 100_00) },
            { it.increase(NEEDS) },
            { it.decrease(NEEDS) },
            { it.decrease(NEEDS) },
            { it.decrease(WANTS) },
            { it.increase(SAVINGS_AND_DEBTS) }
        )

        for (step in steps) {
            step(split)
            assertEquals(split.amountToSplit - split.values.values.sum(), split.remaining)
            assertTrue(split.remaining >= 0)
        }
        assertEquals(mapOf(NEEDS to 29_00, WANTS to 0, SAVINGS_AND_DEBTS to 30_00), split.values)
    }

    @Test
    fun stepUpMovesByFivePercent() {
        val split = RepartitionSplit(3000_00, emptyMap())

        split.stepUp(NEEDS)
        assertEquals(150_00, split.amount(NEEDS))

        split.stepUp(NEEDS)
        assertEquals(300_00, split.amount(NEEDS))
    }

    @Test
    fun stepUpSnapsToNextStep() {
        val split = RepartitionSplit(3000_00, mapOf(NEEDS to 1234_00))

        split.stepUp(NEEDS)

        assertEquals(1350_00, split.amount(NEEDS))
    }

    @Test
    fun stepDownSnapsToPreviousStep() {
        val split = RepartitionSplit(3000_00, mapOf(NEEDS to 1234_00))

        split.stepDown(NEEDS)

        assertEquals(1200_00, split.amount(NEEDS))
    }

    @Test
    fun stepsAreRoundedToWholeUnits() {
        val split = RepartitionSplit(1234_56, emptyMap())

        split.stepUp(NEEDS)
        assertEquals(62_00, split.amount(NEEDS))

        split.stepUp(NEEDS)
        assertEquals(123_00, split.amount(NEEDS))
    }

    @Test
    fun stepUpIsCappedAtRemaining() {
        val split = RepartitionSplit(1234_56, mapOf(WANTS to 1000_00, NEEDS to 200_00))

        split.stepUp(NEEDS)

        assertEquals(234_56, split.amount(NEEDS))
        assertEquals(0, split.remaining)
    }

    @Test
    fun lastStepUpReachesTotal() {
        val split = RepartitionSplit(1234_56, mapOf(NEEDS to 1173_00))

        split.stepUp(NEEDS)

        assertEquals(1234_56, split.amount(NEEDS))
    }

    @Test
    fun stepUpWithNothingLeftDoesNothing() {
        val split = RepartitionSplit(3000_00, mapOf(NEEDS to 1500_00, WANTS to 1500_00))

        split.stepUp(NEEDS)

        assertEquals(1500_00, split.amount(NEEDS))
    }

    @Test
    fun stepDownStopsAtZero() {
        val split = RepartitionSplit(3000_00, mapOf(NEEDS to 40))

        split.stepDown(NEEDS)
        assertEquals(0, split.amount(NEEDS))

        split.stepDown(NEEDS)
        assertEquals(0, split.amount(NEEDS))
    }

    @Test
    fun smallAmountsStepByWholeUnits() {
        val split = RepartitionSplit(5_00, emptyMap())
        val reachedValues = mutableListOf<Int>()

        repeat(10) {
            split.stepUp(NEEDS)
            reachedValues.add(split.amount(NEEDS))
        }

        assertEquals(listOf(1_00, 2_00, 3_00, 4_00, 5_00, 5_00, 5_00, 5_00, 5_00, 5_00), reachedValues)
    }

    @Test
    fun amountBelowOneUnitIsOneStep() {
        val split = RepartitionSplit(60, emptyMap())

        split.stepUp(NEEDS)

        assertEquals(60, split.amount(NEEDS))
    }
}

class ProportionalLayoutTests {
    @Test
    fun lengthsFollowWeights() {
        assertEquals(listOf(50.0, 30.0, 20.0), ProportionalLayout.lengths(listOf(5.0, 3.0, 2.0), availableLength = 100.0))
    }

    @Test
    fun tinySliceGetsTheMinimum() {
        assertEquals(listOf(97.0, 3.0), ProportionalLayout.lengths(listOf(0.99, 0.01), availableLength = 100.0, minimumLength = 3.0))
    }

    @Test
    fun noMinimumKeepsWeightedLength() {
        assertEquals(listOf(99.0, 1.0), ProportionalLayout.lengths(listOf(0.99, 0.01), availableLength = 100.0))
    }
}

class TransactionListFilterTests {
    private fun date(month: Int, day: Int, hour: Int = 0, minute: Int = 0) = calendar.date(2026, month, day, hour, minute)

    private fun insertGroup(title: String, day: Int, entries: Map<BudgetCategory, Int>, month: Month): DisplayableTransaction {
        val type = if (entries.values.sum() < 0) TransactionType.EXPENSE else TransactionType.INCOME
        val group = TransactionGroup(title, type, month, null, null, addedDate = date(10, day, 12))
        entries.forEach { (category, amountCents) -> TransactionEntry(amountCents, category, group) }
        return DisplayableTransaction.Group(group)
    }

    private fun sampleItems(store: TrenteStore): Pair<Month, List<DisplayableTransaction>> {
        val month = insertMonth(2026, 10, store)
        val items = listOf(
            insertGroup("Café", 3, mapOf(WANTS to -4_50), month),
            insertGroup("Rent", 1, mapOf(NEEDS to -800_00), month),
            insertGroup("Salary", 25, mapOf(NEEDS to 1_000_00, WANTS to 500_00), month)
        )
        store.save()
        return month to items
    }

    @Test
    fun freshFilterKeepsEverything() {
        val (month, items) = sampleItems(makeStore())

        assertEquals(listOf("Salary", "Café", "Rent"), TransactionListFilter(month).apply(items).map { it.title })
    }

    @Test
    fun searchIgnoresCaseAndAccents() {
        val (month, items) = sampleItems(makeStore())
        val filter = TransactionListFilter(month)

        filter.searchText = "cafe"

        assertEquals(listOf("Café"), filter.apply(items).map { it.title })
    }

    @Test
    fun categoryFilterKeepsSplitIncome() {
        val (month, items) = sampleItems(makeStore())
        val filter = TransactionListFilter(month)

        filter.categories = setOf(WANTS)

        assertEquals(listOf("Salary", "Café"), filter.apply(items).map { it.title })
    }

    @Test
    fun sortOrders() {
        for (sort in SortOption.entries) {
            val (month, items) = sampleItems(makeStore())
            val filter = TransactionListFilter(month)

            filter.sort = sort

            val expected = when (sort) {
                SortOption.DATE_ASC -> listOf("Rent", "Café", "Salary")
                SortOption.DATE_DESC -> listOf("Salary", "Café", "Rent")
                SortOption.AMOUNT_ASC -> listOf("Rent", "Café", "Salary")
                SortOption.AMOUNT_DESC -> listOf("Salary", "Café", "Rent")
                SortOption.TITLE_ASC -> listOf("Café", "Rent", "Salary")
                SortOption.TITLE_DESC -> listOf("Salary", "Rent", "Café")
            }
            assertEquals(expected, filter.apply(items).map { it.title }, sort.name)
        }
    }

    @Test
    fun activeFilters() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val filter = TransactionListFilter(month)
        filter.searchText = "rent"
        filter.sort = SortOption.TITLE_ASC
        assertFalse(filter.isActive(month))

        val datedFilter = TransactionListFilter(month)
        datedFilter.firstDay = date(10, 5)
        assertTrue(datedFilter.isActive(month))

        val categoryFilter = TransactionListFilter(month)
        categoryFilter.categories = setOf(NEEDS)
        assertTrue(categoryFilter.isActive(month))
    }

    @Test
    fun resetClearsSearchAndFilters() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val filter = TransactionListFilter(month)
        filter.firstDay = date(10, 5)
        filter.lastDay = date(10, 12)
        filter.categories = setOf(NEEDS, WANTS)
        filter.searchText = "rent"
        filter.sort = SortOption.AMOUNT_ASC

        filter.reset(month)

        assertFalse(filter.isActive(month))
        assertEquals(month.startDate, filter.firstDay)
        assertEquals(month.endDate(), filter.lastDay)
        assertTrue(filter.categories.isEmpty())
        assertTrue(filter.searchText.isEmpty())
        assertEquals(SortOption.AMOUNT_ASC, filter.sort)
    }

    @Test
    fun totalOfShownTransactions() {
        val (month, items) = sampleItems(makeStore())
        val filter = TransactionListFilter(month)
        filter.categories = setOf(NEEDS)

        val shown = filter.apply(items)

        assertEquals(-800_00 + 1_500_00, filter.totalCents(shown))
    }

    @Test
    fun includesTheWholeLastDay() {
        val days = TransactionListFilter.days(date(10, 25), date(11, 24))

        assertTrue(days.contains(date(11, 24, 23, 59)))
        assertFalse(days.contains(date(11, 25)))
    }

    @Test
    fun includesTheWholeFirstDayWhenTheMonthStartedLaterThatDay() {
        val days = TransactionListFilter.days(date(10, 25, 14, 32), date(11, 24))

        assertTrue(days.contains(date(10, 25, 9)))
        assertFalse(days.contains(date(10, 24, 23, 59)))
    }

    @Test
    fun monthEndDateKeepsItsLastDay() {
        val month = Month(startDate = date(10, 25, 14), currency = EUR, idealBudgetCents = 0, idealRepartition = emptyMap())

        val days = TransactionListFilter.days(month.startDate, month.endDate())

        assertTrue(days.contains(date(11, 24, 18)))
        assertEquals(month.dateInterval.start, days.start)
        assertEquals(month.dateInterval.end, days.end)
    }

    @Test
    fun emptyWhenTheRangeIsReversed() {
        assertTrue(TransactionListFilter.days(date(11, 24), date(10, 25)).isEmpty)
    }
}

class DisplayableTransactionTests {
    @Test
    fun groupIDIsStable() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val group = TransactionGroup("Coffee", TransactionType.EXPENSE, month, null, null)
        store.save()

        assertEquals(DisplayableTransaction.Group(group).id, DisplayableTransaction.Group(group).id)
    }

    @Test
    fun groupIDsDiffer() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val coffee = TransactionGroup("Coffee", TransactionType.EXPENSE, month, null, null)
        val lunch = TransactionGroup("Lunch", TransactionType.EXPENSE, month, null, null)
        store.save()

        assertTrue(DisplayableTransaction.Group(coffee).id != DisplayableTransaction.Group(lunch).id)
    }

    @Test
    fun occurrenceIDIsStable() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val rule = RecurringTransactionRule("Rent", RecurrenceFrequency.MONTHLY, month.startDate, repartition = mapOf(NEEDS to -800_00), createdAt = month.startDate)
        store.insert(rule)
        store.save()

        val first = RecurringTransactionOccurrence(rule, month.startDate, month)
        val second = RecurringTransactionOccurrence(rule, month.startDate, month)

        assertEquals(DisplayableTransaction.Recurring(first).id, DisplayableTransaction.Recurring(second).id)
    }
}

class TransactionGroupDraftTests {
    private fun makeExpense(amountCents: Int, category: BudgetCategory): TransactionGroup {
        val group = TransactionGroup("Groceries", TransactionType.EXPENSE, makeMonth(), null, null)
        TransactionEntry(amountCents, category, group)
        return group
    }

    private fun makeIncome(repartition: Map<BudgetCategory, Int>): TransactionGroup {
        val group = TransactionGroup("Salary", TransactionType.INCOME, makeMonth(), null, null)
        repartition.forEach { (category, amountCents) -> TransactionEntry(amountCents, category, group) }
        return group
    }

    @Test
    fun positiveExpenseAmountBecomesNegative() {
        val draft = TransactionGroupDraft.from(makeExpense(-12_00, NEEDS))

        draft.expenseAmountCents = 45_50

        assertEquals(-45_50, draft.expenseAmountCents)
    }

    @Test
    fun negativeExpenseAmountIsKept() {
        val draft = TransactionGroupDraft.from(makeExpense(-12_00, NEEDS))

        draft.expenseAmountCents = -8_00

        assertEquals(-8_00, draft.expenseAmountCents)
    }

    @Test
    fun categoryChangeKeepsExpenseAmount() {
        val draft = TransactionGroupDraft.from(makeExpense(-12_00, NEEDS))

        draft.expenseCategory = WANTS

        assertEquals(WANTS, draft.expenseCategory)
        assertEquals(-12_00, draft.expenseAmountCents)
    }

    @Test
    fun missingAmountToSplitUsesRepartitionTotal() {
        val draft = TransactionGroupDraft.from(makeIncome(mapOf(NEEDS to 600_00)))
        draft.incomeAmountToSplitCents = 0
        draft.incomeRepartition = mapOf(NEEDS to 500_00, WANTS to 300_00)

        draft.fillMissingAmountToSplit()

        assertEquals(800_00, draft.incomeAmountToSplitCents)
        assertTrue(draft.validate().isEmpty())
    }

    @Test
    fun existingAmountToSplitIsKept() {
        val draft = TransactionGroupDraft.from(makeIncome(mapOf(NEEDS to 600_00, WANTS to 400_00)))

        draft.incomeRepartition = mapOf(NEEDS to 600_00)
        draft.fillMissingAmountToSplit()

        assertEquals(1000_00, draft.incomeAmountToSplitCents)
    }

    @Test
    fun fillingAmountToSplitIgnoresExpenses() {
        val draft = TransactionGroupDraft.from(makeExpense(-12_00, NEEDS))
        draft.incomeRepartition = mapOf(NEEDS to 50_00)

        draft.fillMissingAmountToSplit()

        assertEquals(0, draft.incomeAmountToSplitCents)
    }

    private fun insertGroup(type: TransactionType, entries: Map<BudgetCategory, Int>, note: String?, store: TrenteStore): TransactionGroup {
        val month = insertMonth(2026, 10, store)
        val group = TransactionGroup("Groceries", type, month, note, null)
        entries.forEach { (category, amountCents) -> TransactionEntry(amountCents, category, group) }
        return group
    }

    private fun amountsByCategory(group: TransactionGroup) = group.entries.groupBy { it.category }.mapValues { (_, entries) -> entries.sumOf { it.amountCents } }

    @Test
    fun untouchedDraftRoundTrips() {
        for (type in TransactionType.entries) {
            val store = makeStore()
            val entries = if (type == TransactionType.EXPENSE) mapOf(NEEDS to -12_00) else mapOf(NEEDS to 600_00, WANTS to 400_00)
            val group = insertGroup(type, entries, "Weekly", store)
            store.save()

            TransactionGroupDraft.from(group).apply(group, store)

            assertEquals("Groceries", group.title)
            assertEquals("Weekly", group.note)
            assertEquals(entries, amountsByCategory(group))
        }
    }

    @Test
    fun emptyNoteIsSavedAsNoNote() {
        val store = makeStore()
        val group = insertGroup(TransactionType.EXPENSE, mapOf(NEEDS to -12_00), "Weekly", store)
        store.save()
        val draft = TransactionGroupDraft.from(group)

        draft.note = ""
        draft.apply(group, store)

        assertNull(group.note)
    }
}

class RecurringTransactionRuleDraftTests {
    private fun daysFromToday(days: Long) = calendar.plusDays(calendar.startOfDay(Instant.now()), days)

    private fun makeRule(frequency: RecurrenceFrequency, startDate: Instant, endDate: Instant? = null) =
        RecurringTransactionRule("Rent", frequency, startDate, endDate, repartition = mapOf(NEEDS to -800_00), createdAt = startDate)

    @Test
    fun frequencyChangeRestartsOnNextDate() {
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.WEEKLY, daysFromToday(-13)))

        draft.setFrequency(RecurrenceFrequency.MONTHLY)

        assertEquals(daysFromToday(1), draft.startDate)
        assertTrue(draft.validate().isEmpty())
    }

    @Test
    fun frequencyChangeKeepsFutureStart() {
        val startDate = daysFromToday(10)
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.MONTHLY, startDate))

        draft.setFrequency(RecurrenceFrequency.WEEKLY)

        assertEquals(startDate, draft.startDate)
    }

    @Test
    fun stoppedBeforeStartCanBeEdited() {
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.MONTHLY, daysFromToday(10), daysFromToday(0)))

        draft.title = "Flat rent"

        assertTrue(draft.validate().isEmpty())
    }

    @Test
    fun categoryChangeMovesExpenseAmount() {
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.MONTHLY, daysFromToday(10)))

        draft.expenseCategory = WANTS

        assertEquals(WANTS, draft.expenseCategory)
        assertEquals(mapOf(WANTS to -800_00), draft.repartition)
        assertTrue(draft.validate().isEmpty())
    }

    @Test
    fun clearingCategoryKeepsRepartition() {
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.MONTHLY, daysFromToday(10)))

        draft.expenseCategory = null

        assertEquals(mapOf(NEEDS to -800_00), draft.repartition)
    }

    @Test
    fun expenseAmountIsStoredNegative() {
        val draft = RecurringTransactionRuleDraft.from(makeRule(RecurrenceFrequency.MONTHLY, daysFromToday(10)))

        draft.expenseAmountCents = 950_00

        assertEquals(-950_00, draft.expenseAmountCents)
        assertEquals(-950_00, draft.repartitionTotalCents)
        assertEquals(mapOf(NEEDS to -950_00), draft.repartition)
        assertTrue(draft.validate().isEmpty())
    }

    @Test
    fun untouchedDraftRoundTrips() {
        val rule = makeRule(RecurrenceFrequency.MONTHLY, daysFromToday(-40), daysFromToday(200))
        rule.autoConfirm = true

        RecurringTransactionRuleDraft.from(rule).apply(rule)

        assertEquals("Rent", rule.title)
        assertEquals(RecurrenceFrequency.MONTHLY, rule.frequency)
        assertEquals(daysFromToday(-40), rule.startDate)
        assertEquals(daysFromToday(200), rule.endDate)
        assertTrue(rule.autoConfirm)
        assertEquals(mapOf(NEEDS to -800_00), rule.repartition)
    }
}

class NewTransactionViewModelTests {
    private fun rentViewModel(isRecurrent: Boolean, center: FakeNotificationCenter, scope: kotlinx.coroutines.CoroutineScope): NewTransactionViewModel {
        val viewModel = NewTransactionViewModel(scope, NotificationPermissionService(center))
        viewModel.request.title = "Rent"
        viewModel.request.amountCents = -800_00
        viewModel.request.selectedCategory = NEEDS
        viewModel.request.isRecurrent = isRecurrent
        return viewModel
    }

    @Test
    fun asksForNotificationsOnlyWhenRecurring() = runTest {
        for (isRecurrent in listOf(true, false)) {
            val store = makeStore()
            val today = calendar.localDate(Instant.now())
            val month = insertMonth(today.year, today.monthValue, store)
            val center = FakeNotificationCenter(NotificationPermissionStatus.NOT_DETERMINED, grants = true)
            val viewModel = rentViewModel(isRecurrent, center, this)

            assertTrue(viewModel.createTransaction(month, store))
            viewModel.permissionRequest?.join()

            assertEquals(if (isRecurrent) 1 else 0, center.requestCount)
        }
    }

    @Test
    fun expenseNeedsAmountAndCategory() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.request.type = TransactionType.EXPENSE
        assertFalse(viewModel.canAdvance)

        viewModel.request.amountCents = -12_00
        assertFalse(viewModel.canAdvance)

        viewModel.request.selectedCategory = WANTS
        assertTrue(viewModel.canAdvance)

        viewModel.request.amountCents = 0
        assertFalse(viewModel.canAdvance)
    }

    @Test
    fun incomeNeedsOnlyAmount() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.request.type = TransactionType.INCOME
        assertFalse(viewModel.canAdvance)

        viewModel.request.amountCents = 1_500_00
        assertTrue(viewModel.canAdvance)
    }

    @Test
    fun titleStepNeedsTitle() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.step = NewTransactionStep.TITLE
        assertFalse(viewModel.canAdvance)

        viewModel.request.title = "Groceries"
        assertTrue(viewModel.canAdvance)
    }

    @Test
    fun incomeSplitComesAfterTitle() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.request.type = TransactionType.INCOME
        viewModel.request.isRecurrent = true

        assertEquals(
            listOf(NewTransactionStep.AMOUNT_CATEGORY, NewTransactionStep.TITLE, NewTransactionStep.REPARTITION, NewTransactionStep.NOTES_IMAGE, NewTransactionStep.RECURRENCE),
            viewModel.filteredSteps
        )
    }

    @Test
    fun repartitionStepNeedsCompleteSplit() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.step = NewTransactionStep.REPARTITION
        assertFalse(viewModel.canAdvance)

        viewModel.isRepartitionComplete = true
        assertTrue(viewModel.canAdvance)
    }

    @Test
    fun optionalStepsAlwaysAdvance() = runTest {
        for (step in listOf(NewTransactionStep.NOTES_IMAGE, NewTransactionStep.RECURRENCE)) {
            val viewModel = NewTransactionViewModel(this)
            viewModel.step = step
            assertTrue(viewModel.canAdvance)
        }
    }

    private fun incomeAtTitleStep(amountCents: Int, scope: kotlinx.coroutines.CoroutineScope): NewTransactionViewModel {
        val viewModel = NewTransactionViewModel(scope)
        viewModel.request.type = TransactionType.INCOME
        viewModel.request.amountCents = amountCents
        viewModel.step = NewTransactionStep.TITLE
        return viewModel
    }

    @Test
    fun splitStartsAtZero() = runTest {
        val viewModel = incomeAtTitleStep(1_000_00, this)

        viewModel.nextStep()

        assertEquals(NewTransactionStep.REPARTITION, viewModel.step)
        assertEquals(mapOf(NEEDS to 0, WANTS to 0, SAVINGS_AND_DEBTS to 0), viewModel.request.repartition)
    }

    @Test
    fun splitSurvivesBackAndNext() = runTest {
        val viewModel = incomeAtTitleStep(1_000_00, this)
        viewModel.nextStep()
        viewModel.request.repartition = mapOf(NEEDS to 500_00, WANTS to 200_00, SAVINGS_AND_DEBTS to 0)

        viewModel.previousStep()
        viewModel.nextStep()

        assertEquals(mapOf(NEEDS to 500_00, WANTS to 200_00, SAVINGS_AND_DEBTS to 0), viewModel.request.repartition)
    }

    @Test
    fun splitResetsWhenAmountChanged() = runTest {
        val viewModel = incomeAtTitleStep(1_000_00, this)
        viewModel.nextStep()
        viewModel.request.repartition = mapOf(NEEDS to 1_000_00, WANTS to 0, SAVINGS_AND_DEBTS to 0)

        viewModel.previousStep()
        viewModel.request.amountCents = 1_200_00
        viewModel.nextStep()

        assertEquals(mapOf(NEEDS to 0, WANTS to 0, SAVINGS_AND_DEBTS to 0), viewModel.request.repartition)
    }

    @Test
    fun photoSurvivesLeavingTheStep() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.request.isRecurrent = true
        viewModel.step = NewTransactionStep.NOTES_IMAGE
        val gate = CompletableDeferred<Unit>()

        viewModel.loadImage {
            gate.await()
            "photo".toByteArray()
        }
        assertTrue(viewModel.canAdvance)
        viewModel.nextStep()
        gate.complete(Unit)
        viewModel.imageLoader.currentLoad?.join()

        assertEquals(NewTransactionStep.RECURRENCE, viewModel.step)
        assertTrue("photo".toByteArray().contentEquals(viewModel.request.imageData))
        assertFalse(viewModel.isLoadingImage)
    }

    @Test
    fun createWaitsForLoadingPhoto() = runTest {
        val viewModel = NewTransactionViewModel(this)
        viewModel.step = NewTransactionStep.NOTES_IMAGE
        val gate = CompletableDeferred<Unit>()

        viewModel.loadImage {
            gate.await()
            "photo".toByteArray()
        }
        assertTrue(viewModel.isLastStep)
        assertFalse(viewModel.canAdvance)

        gate.complete(Unit)
        viewModel.imageLoader.currentLoad?.join()
        assertTrue(viewModel.canAdvance)
    }
}

class ImageAttachmentLoaderTests {
    @Test
    fun newerPhotoWins() = runTest {
        val loader = ImageAttachmentLoader(this)
        val gate = CompletableDeferred<Unit>()
        val loadedData = mutableListOf<ByteArray>()

        loader.load({
            gate.await()
            "older".toByteArray()
        }) { loadedData.add(it) }
        val olderLoad = loader.currentLoad
        loader.load({ "newer".toByteArray() }) { loadedData.add(it) }
        loader.currentLoad?.join()
        gate.complete(Unit)
        olderLoad?.join()

        assertEquals(listOf("newer"), loadedData.map { String(it) })
        assertFalse(loader.isLoading)
    }

    @Test
    fun failedPhotoDeliversNothing() = runTest {
        for (throwsError in listOf(true, false)) {
            val loader = ImageAttachmentLoader(this)
            val loadedData = mutableListOf<ByteArray>()

            loader.load({
                if (throwsError) throw IllegalStateException("unreadable")
                null
            }) { loadedData.add(it) }
            loader.currentLoad?.join()

            assertTrue(loadedData.isEmpty())
            assertNotNull(loader.error)
            assertFalse(loader.isLoading)
        }
    }
}

class OnboardingModelTests {
    @Test
    fun defaultDraft() {
        val today = Instant.now()
        val model = OnboardingModel(steps = OnboardingStep.entries, locale = Locale.US, startDate = today)

        assertEquals("USD", model.draft.currency.isoCode)
        assertEquals(today, model.draft.startDate)
        assertEquals(0, model.draft.idealBudgetCents)
        assertTrue(model.draft.idealRepartition.values.all { it == 0 })
    }

    @Test
    fun defaultCurrencyFallback() {
        assertEquals("EUR", OnboardingModel.defaultCurrency(Locale("ar", "EG")).isoCode)
    }

    @Test
    fun navigation() {
        val model = OnboardingModel(steps = listOf(OnboardingStep.WELCOME, OnboardingStep.BUDGET, OnboardingStep.ALL_SET))

        assertEquals(OnboardingStep.WELCOME, model.currentStep)
        assertFalse(model.canGoBack)

        model.goBack()
        assertEquals(OnboardingStep.WELCOME, model.currentStep)

        model.goForward()
        assertEquals(OnboardingStep.BUDGET, model.currentStep)
        assertEquals(OnboardingDirection.FORWARD, model.direction)

        model.goForward()
        assertEquals(OnboardingStep.ALL_SET, model.currentStep)
        assertTrue(model.isLastStep)

        model.goForward()
        assertEquals(OnboardingStep.ALL_SET, model.currentStep)

        model.goBack()
        assertEquals(OnboardingStep.BUDGET, model.currentStep)
        assertEquals(OnboardingDirection.BACKWARD, model.direction)
    }

    @Test
    fun suggestedRepartition() {
        data class Case(val budgetCents: Int, val needs: Int, val wants: Int, val savings: Int)
        for (case in listOf(Case(2000_00, 1000_00, 600_00, 400_00), Case(1234_00, 617_00, 370_00, 247_00), Case(1234_56, 617_00, 370_00, 247_56), Case(0, 0, 0, 0))) {
            val repartition = OnboardingModel.suggestedRepartition(case.budgetCents)

            assertEquals(case.needs, repartition[NEEDS])
            assertEquals(case.wants, repartition[WANTS])
            assertEquals(case.savings, repartition[SAVINGS_AND_DEBTS])
            assertEquals(case.budgetCents, repartition.values.sum())
        }
    }

    @Test
    fun budgetChangeKeepsSuggestedSplit() {
        val model = OnboardingModel(steps = OnboardingStep.entries)

        model.budgetCents = 2000_00
        model.budgetCents = 1500_00

        assertEquals(OnboardingModel.suggestedRepartition(1500_00), model.draft.idealRepartition)
    }

    @Test
    fun raisedBudgetKeepsAdjustedSplit() {
        val model = OnboardingModel(steps = OnboardingStep.entries)
        model.budgetCents = 2000_00
        val adjusted = mapOf(NEEDS to 1200_00, WANTS to 400_00, SAVINGS_AND_DEBTS to 400_00)
        model.draft.idealRepartition = adjusted

        model.budgetCents = 2500_00

        assertEquals(adjusted, model.draft.idealRepartition)
    }

    @Test
    fun loweredBudgetResetsAdjustedSplit() {
        val model = OnboardingModel(steps = OnboardingStep.entries)
        model.budgetCents = 2000_00
        model.draft.idealRepartition = mapOf(NEEDS to 1200_00, WANTS to 400_00, SAVINGS_AND_DEBTS to 400_00)

        model.budgetCents = 1000_00

        assertEquals(OnboardingModel.suggestedRepartition(1000_00), model.draft.idealRepartition)
    }

    @Test
    fun savingTwiceUpdatesTheSameMonth() {
        val store = makeStore()
        val model = OnboardingModel(steps = OnboardingStep.entries)
        model.budgetCents = 2000_00

        model.saveMonth(store)
        model.budgetCents = 2500_00
        model.saveMonth(store)

        assertEquals(1, store.months.size)
        assertEquals(2500_00, store.months.first().idealBudgetCents)
        assertEquals(OnboardingModel.suggestedRepartition(2500_00), store.months.first().idealRepartition)
    }

    @Test
    fun firstLaunchReusesMonthSavedByAnotherWindow() {
        val store = makeStore()
        val firstWindow = OnboardingModel(steps = OnboardingStep.entries)
        val secondWindow = OnboardingModel(steps = OnboardingStep.entries)
        firstWindow.budgetCents = 2000_00
        secondWindow.budgetCents = 3000_00

        firstWindow.saveMonth(store, reusingExistingMonth = true)
        secondWindow.saveMonth(store, reusingExistingMonth = true)

        assertEquals(1, store.months.size)
        assertEquals(3000_00, store.months.first().idealBudgetCents)
    }

    @Test
    fun replayKeepsExistingMonth() {
        val store = makeStore()
        val firstLaunch = OnboardingModel(steps = OnboardingStep.entries)
        firstLaunch.budgetCents = 2000_00
        firstLaunch.saveMonth(store, reusingExistingMonth = true)

        val replay = OnboardingModel(steps = OnboardingStep.entries)
        replay.budgetCents = 3000_00
        replay.saveMonth(store)

        assertEquals(listOf(2000_00, 3000_00), store.months.map { it.idealBudgetCents }.sorted())
    }

    @Test
    fun addingIncome() {
        val store = makeStore()
        val today = calendar.date(2026, 10, 29, 14)
        val model = OnboardingModel(steps = OnboardingStep.entries, startDate = today)
        model.budgetCents = 2000_00
        model.saveMonth(store)

        model.addIncome(store, now = today)

        val month = model.savedMonth!!
        val income = month.transactionGroups.first()
        val rule = income.recurringRule!!
        assertEquals(1, month.transactionGroups.size)
        assertEquals(TransactionType.INCOME, income.type)
        assertEquals(calendar.startOfDay(today), income.addedDate)
        assertEquals(2000.0, month.remainingAmount)
        assertEquals(RecurrenceFrequency.MONTHLY, rule.frequency)
        assertFalse(rule.autoConfirm)
        assertEquals(OnboardingModel.suggestedRepartition(2000_00), rule.repartition)
        assertEquals(month.dateInterval.end, rule.startDate)
        assertTrue(rule.pendingOccurrences(month).isEmpty())
    }

    @Test
    fun addingIncomeTwiceAddsItOnce() {
        val store = makeStore()
        val model = OnboardingModel(steps = OnboardingStep.entries)
        model.budgetCents = 2000_00
        model.saveMonth(store)

        model.addIncome(store)
        model.addIncome(store)

        assertEquals(1, store.rules.size)
        assertEquals(1, store.transactionGroups.size)
    }

    @Test
    fun incomeStartDate() {
        val cases = listOf(
            Triple(Triple(2026, 10, 29), Triple(2026, 10, 29), Triple(2026, 11, 29)),
            Triple(Triple(2026, 10, 1), Triple(2026, 10, 29), Triple(2026, 11, 1)),
            Triple(Triple(2026, 8, 15), Triple(2026, 10, 29), Triple(2026, 11, 15)),
            Triple(Triple(2026, 9, 29), Triple(2026, 10, 29), Triple(2026, 10, 29)),
            Triple(Triple(2026, 11, 5), Triple(2026, 10, 29), Triple(2026, 12, 5)),
            Triple(Triple(2027, 1, 31), Triple(2027, 1, 31), Triple(2027, 2, 28))
        )
        fun date(components: Triple<Int, Int, Int>) = calendar.date(components.first, components.second, components.third)
        for ((monthStart, today, expected) in cases) {
            assertEquals(date(expected), OnboardingModel.incomeStartDate(date(monthStart), date(today), calendar), "$monthStart / $today")
        }
    }

    @Test
    fun gate() {
        val cases = listOf(
            listOf(false, 0, false, true),
            listOf(true, 0, false, false),
            listOf(false, 1, false, false),
            listOf(true, 3, false, false),
            listOf(true, 3, true, true)
        )
        for (case in cases) {
            val shouldShow = OnboardingGate.shouldShow(
                hasCompletedOnboarding = case[0] as Boolean,
                monthCount = case[1] as Int,
                isForced = case[2] as Boolean
            )
            assertEquals(case[3] as Boolean, shouldShow, "$case")
        }
    }
}
