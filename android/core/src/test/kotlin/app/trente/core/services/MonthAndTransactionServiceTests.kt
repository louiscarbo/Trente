package app.trente.core.services

import app.trente.core.EUR
import app.trente.core.insertMonth
import app.trente.core.makeStore
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
import app.trente.core.model.TrenteDates
import app.trente.core.model.TrenteStore
import app.trente.core.parisCalendar
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MonthServiceTests {
    private val calendar = TrenteCalendar.current

    @Test
    fun latestMonth() {
        val store = makeStore()
        insertMonth(2026, 8, store)
        val latest = insertMonth(2026, 10, store)
        insertMonth(2026, 9, store)

        assertEquals(latest.id, MonthService.latestMonth(store)?.id)
    }

    @Test
    fun latestMonthWithoutMonths() {
        assertNull(MonthService.latestMonth(makeStore()))
    }

    @Test
    fun monthContainingBoundary() {
        val store = makeStore()
        insertMonth(2026, 10, store)
        val november = insertMonth(2026, 11, store)
        val midnight = calendar.date(2026, 11, 1)

        assertEquals(november.id, MonthService.monthContaining(midnight, store)?.id)
        assertNull(MonthService.monthContaining(TrenteDates.distantPast, store))
    }

    private data class MissingMonthsCase(
        val description: String,
        val latestStartDate: Instant?,
        val today: Instant,
        val expectedStartDates: List<Instant>
    )

    @Test
    fun startDatesOfMissingMonths() {
        val paris = parisCalendar()
        fun paris(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) = paris.date(year, month, day, hour, minute)
        val cases = listOf(
            MissingMonthsCase("No months", null, paris(2026, 10, 23), emptyList()),
            MissingMonthsCase("Today inside the latest month", paris(2026, 10, 1), paris(2026, 10, 23, 12), emptyList()),
            MissingMonthsCase("Midnight on the boundary", paris(2026, 10, 1), paris(2026, 11, 1), listOf(paris(2026, 11, 1))),
            MissingMonthsCase("Last minute of the month", paris(2026, 10, 1), paris(2026, 10, 31, 23, 59), emptyList()),
            MissingMonthsCase(
                "Three months away",
                paris(2026, 7, 1),
                paris(2026, 10, 23),
                listOf(paris(2026, 8, 1), paris(2026, 9, 1), paris(2026, 10, 1))
            ),
            MissingMonthsCase("Starts on the 25th", paris(2026, 9, 25), paris(2026, 11, 2), listOf(paris(2026, 10, 25))),
            MissingMonthsCase(
                "January 31 chains to February 28 then March 28",
                paris(2026, 1, 31),
                paris(2026, 3, 30),
                listOf(paris(2026, 2, 28), paris(2026, 3, 28))
            ),
            MissingMonthsCase(
                "Time of day on the stored start is ignored",
                paris(2026, 9, 1, 14, 30),
                paris(2026, 10, 1, 8),
                listOf(paris(2026, 10, 1))
            ),
            MissingMonthsCase(
                "Daylight saving time ends during the month",
                paris(2026, 10, 1),
                paris(2026, 11, 1, 0, 30),
                listOf(paris(2026, 11, 1))
            ),
            MissingMonthsCase(
                "Starts on the day daylight saving time ends",
                paris(2026, 10, 25),
                paris(2026, 11, 25),
                listOf(paris(2026, 11, 25))
            ),
            MissingMonthsCase("Latest month in the future", paris(2026, 12, 1), paris(2026, 10, 23), emptyList())
        )

        for (case in cases) {
            val startDates = MonthService.startDatesOfMissingMonths(case.latestStartDate, case.today, paris)
            assertEquals(case.expectedStartDates, startDates, case.description)
        }
    }

    @Test
    fun createMissingMonthsCopiesLatest() {
        val store = makeStore()
        val latest = insertMonth(2026, 8, store)
        latest.currency = Currencies.currency("USD")!!
        latest.idealBudgetCents = 3100_00
        latest.idealRepartition = mapOf(NEEDS to 60, WANTS to 20, SAVINGS_AND_DEBTS to 20)
        val today = calendar.date(2026, 10, 23)

        val created = MonthService.createMissingMonths(store, now = today)

        assertEquals(listOf(calendar.date(2026, 9, 1), calendar.date(2026, 10, 1)), created.map { it.startDate })
        for (month in created) {
            assertEquals(latest.currency, month.currency)
            assertEquals(3100_00, month.idealBudgetCents)
            assertEquals(latest.idealRepartition, month.idealRepartition)
        }
        assertEquals(3, store.months.size)
        assertFalse(store.hasChanges)
    }

    @Test
    fun createMissingMonthsTwice() {
        val store = makeStore()
        insertMonth(2026, 8, store)
        val today = calendar.date(2026, 10, 23)

        MonthService.createMissingMonths(store, now = today)
        val createdAgain = MonthService.createMissingMonths(store, now = today)

        assertTrue(createdAgain.isEmpty())
        assertEquals(3, store.months.size)
    }

    @Test
    fun createMissingMonthsWithoutMonths() {
        val store = makeStore()

        val created = MonthService.createMissingMonths(store)

        assertTrue(created.isEmpty())
        assertTrue(store.months.isEmpty())
    }
}

class TransactionServiceTests {
    private val calendar = TrenteCalendar.current

    private fun makeMonth(store: TrenteStore): Month {
        val month = Month(
            startDate = calendar.date(2025, 4, 1),
            currency = EUR,
            idealBudgetCents = 2000_00,
            idealRepartition = mapOf(NEEDS to 50, WANTS to 30, SAVINGS_AND_DEBTS to 20)
        )
        store.insert(month)
        return month
    }

    @Test
    fun deletePlainGroup() {
        val store = makeStore()
        val month = makeMonth(store)
        val group = TransactionGroup(title = "Coffee", type = TransactionType.EXPENSE, month = month, note = null, imageAttachmentData = null)
        TransactionEntry(amountCents = -5_00, category = WANTS, group = group)
        store.save()

        TransactionService.delete(group, store)
        store.save()

        assertTrue(store.transactionGroups.isEmpty())
        assertTrue(store.transactionEntries.isEmpty())
    }

    private fun insertCurrentMonth(store: TrenteStore): Month {
        val today = calendar.localDate(Instant.now())
        return insertMonth(today.year, today.monthValue, store)
    }

    private fun recurringRequest(type: TransactionType, startingOn: Instant = Instant.now()): TransactionCreationRequest {
        val request = TransactionCreationRequest()
        request.isRecurrent = true
        request.recurrenceStartDate = startingOn
        request.type = type
        when (type) {
            TransactionType.INCOME -> {
                request.title = "Salary"
                request.amountCents = 2000_00
                request.repartition = mapOf(NEEDS to 2000_00)
            }
            TransactionType.EXPENSE -> {
                request.title = "Rent"
                request.amountCents = -800_00
                request.selectedCategory = NEEDS
            }
        }
        return request
    }

    @Test
    fun recurringTransactionStartingTodayStaysPending() {
        val store = makeStore()
        val month = insertCurrentMonth(store)

        TransactionService.create(recurringRequest(TransactionType.INCOME), month, store)

        val rule = store.rules.first()
        assertTrue(store.transactionGroups.isEmpty())
        val pending = RecurringTransactionService.pendingOccurrences(listOf(rule), month)
        assertEquals(listOf(calendar.startOfDay(Instant.now())), pending.map { it.date })
    }

    @Test
    fun recurringExpenseKeepsCategoryAndAmount() {
        val store = makeStore()
        val month = insertCurrentMonth(store)

        TransactionService.create(recurringRequest(TransactionType.EXPENSE), month, store)

        assertEquals(mapOf(NEEDS to -800_00), store.rules.first().repartition)
    }

    @Test
    fun recurringTransactionStartingLaterRecordsNothing() {
        val store = makeStore()
        val month = insertCurrentMonth(store)
        val nextWeek = calendar.plusDays(Instant.now(), 7)

        TransactionService.create(recurringRequest(TransactionType.EXPENSE, nextWeek), month, store)

        assertTrue(store.transactionGroups.isEmpty())
        assertEquals(1, store.rules.size)
    }

    @Test
    fun recurringTransactionCannotStartInPast() {
        val store = makeStore()
        val month = insertCurrentMonth(store)
        val yesterday = calendar.plusDays(Instant.now(), -1)

        assertFailsWith<TransactionServiceError.RecurrenceStartsInPast> {
            TransactionService.create(recurringRequest(TransactionType.EXPENSE, yesterday), month, store)
        }
        assertTrue(store.rules.isEmpty())
    }

    @Test
    fun dateBoundsSpanTransactions() {
        val store = makeStore()
        val month = makeMonth(store)
        val dates = listOf(12, 3, 27).map { calendar.date(2025, 4, it) }
        for (date in dates) {
            TransactionGroup(title = "Coffee", type = TransactionType.EXPENSE, month = month, note = null, imageAttachmentData = null, addedDate = date)
        }
        store.save()

        val bounds = TransactionService.fetchTransactionDateBounds(store)

        assertEquals(dates.min()..dates.max(), bounds)
    }

    @Test
    fun dateBoundsWithoutTransactions() {
        val bounds = TransactionService.fetchTransactionDateBounds(makeStore())

        assertEquals(TrenteDates.distantPast..TrenteDates.distantFuture, bounds)
    }
}

class CatchUpServiceTests {
    private val calendar = TrenteCalendar.current

    private fun day(year: Int, month: Int, day: Int) = calendar.date(year, month, day)

    @Test
    fun catchUpCreatesMonthsThenConfirms() {
        val store = makeStore()
        insertMonth(2026, 8, store)
        store.insert(
            RecurringTransactionRule(
                title = "Rent",
                frequency = RecurrenceFrequency.MONTHLY,
                startDate = day(2026, 8, 2),
                autoConfirm = true,
                repartition = mapOf(NEEDS to -800_00),
                createdAt = day(2026, 8, 2)
            )
        )
        store.save()

        CatchUpService.catchUp(store, now = day(2026, 10, 10), isTrentePlusSubscribed = true)

        val months = store.months.sortedBy { it.startDate }
        assertEquals(listOf(day(2026, 8, 1), day(2026, 9, 1), day(2026, 10, 1)), months.map { it.startDate })
        assertEquals(listOf(1, 1, 1), months.map { it.transactionGroups.size })
    }
}
