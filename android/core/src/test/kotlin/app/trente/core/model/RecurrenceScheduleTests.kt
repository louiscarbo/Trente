package app.trente.core.model

import app.trente.core.parisCalendar
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurrenceScheduleTests {
    private val calendar = TrenteCalendar.current

    private fun day(year: Int, month: Int, day: Int, hour: Int = 0) = calendar.date(year, month, day, hour)

    private fun calendarMonth(year: Int, month: Int): DateInterval {
        val start = day(year, month, 1)
        return DateInterval(start, calendar.plusMonths(start, 1))
    }

    private fun schedule(
        frequency: RecurrenceFrequency,
        start: Instant,
        end: Instant? = null,
        earliest: Instant? = null
    ) = RecurrenceSchedule(frequency = frequency, startDate = start, endDate = end, earliestDate = earliest ?: start)

    @Test
    fun monthlyOnAnchorDay() {
        val dates = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 15)).dates(calendarMonth(2025, 2), calendar)

        assertEquals(listOf(day(2025, 2, 15)), dates)
    }

    @Test
    fun monthlyClampsToLastDay() {
        val rule = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 31))

        assertEquals(listOf(day(2025, 2, 28)), rule.dates(calendarMonth(2025, 2), calendar))
        assertEquals(listOf(day(2025, 4, 30)), rule.dates(calendarMonth(2025, 4), calendar))
        assertEquals(listOf(day(2025, 5, 31)), rule.dates(calendarMonth(2025, 5), calendar))
        assertEquals(listOf(day(2028, 2, 29)), rule.dates(calendarMonth(2028, 2), calendar))
    }

    @Test
    fun weeklyOnAnchorWeekday() {
        val dates = schedule(RecurrenceFrequency.WEEKLY, day(2025, 4, 2)).dates(calendarMonth(2025, 4), calendar)

        assertEquals(listOf(2, 9, 16, 23, 30).map { day(2025, 4, it) }, dates)
    }

    @Test
    fun yearlyLeapDay() {
        val rule = schedule(RecurrenceFrequency.YEARLY, day(2024, 2, 29))

        assertEquals(listOf(day(2025, 2, 28)), rule.dates(calendarMonth(2025, 2), calendar))
        assertEquals(listOf(day(2028, 2, 29)), rule.dates(calendarMonth(2028, 2), calendar))
        assertTrue(rule.dates(calendarMonth(2025, 3), calendar).isEmpty())
    }

    @Test
    fun startTimeIsIgnored() {
        val weekly = schedule(RecurrenceFrequency.WEEKLY, day(2025, 4, 2, hour = 14))
        val yearly = schedule(RecurrenceFrequency.YEARLY, day(2025, 4, 2, hour = 14))

        assertEquals(day(2025, 4, 2), weekly.dates(calendarMonth(2025, 4), calendar).first())
        assertEquals(listOf(day(2025, 4, 2)), yearly.dates(calendarMonth(2025, 4), calendar))
    }

    @Test
    fun nothingBeforeStart() {
        val dates = schedule(RecurrenceFrequency.MONTHLY, day(2025, 6, 1)).dates(calendarMonth(2025, 5), calendar)

        assertTrue(dates.isEmpty())
    }

    @Test
    fun nothingBeforeEarliestDate() {
        val rule = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 15), earliest = day(2025, 3, 20, hour = 9))

        assertTrue(rule.dates(calendarMonth(2025, 2), calendar).isEmpty())
        assertTrue(rule.dates(calendarMonth(2025, 3), calendar).isEmpty())
        assertEquals(listOf(day(2025, 4, 15)), rule.dates(calendarMonth(2025, 4), calendar))
    }

    @Test
    fun earliestDayIsIncluded() {
        val rule = schedule(RecurrenceFrequency.MONTHLY, day(2025, 3, 20), earliest = day(2025, 3, 20, hour = 18))

        assertEquals(listOf(day(2025, 3, 20)), rule.dates(calendarMonth(2025, 3), calendar))
    }

    @Test
    fun endDateIsInclusive() {
        val rule = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 15), end = day(2025, 3, 15, hour = 8))

        assertEquals(listOf(day(2025, 3, 15)), rule.dates(calendarMonth(2025, 3), calendar))
        assertTrue(rule.dates(calendarMonth(2025, 4), calendar).isEmpty())
    }

    @Test
    fun budgetMonthStartingMidMonth() {
        val budgetMonth = DateInterval(day(2025, 1, 25), day(2025, 2, 25))

        assertEquals(listOf(day(2025, 2, 10)), schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 10)).dates(budgetMonth, calendar))
        assertEquals(listOf(day(2025, 1, 28)), schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 28)).dates(budgetMonth, calendar))
    }

    @Test
    fun firstDateOnOrAfter() {
        val weekly = schedule(RecurrenceFrequency.WEEKLY, day(2025, 1, 1))
        val monthly = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 15))

        assertEquals(day(2025, 1, 15), weekly.firstDate(onOrAfter = day(2025, 1, 10), calendar = calendar))
        assertEquals(day(2025, 2, 15), monthly.firstDate(onOrAfter = day(2025, 2, 15, hour = 9), calendar = calendar))
    }

    @Test
    fun firstDateAfterEnd() {
        val ended = schedule(RecurrenceFrequency.MONTHLY, day(2025, 1, 15), end = day(2025, 3, 15))

        assertNull(ended.firstDate(onOrAfter = day(2025, 3, 16), calendar = calendar))
    }
}

class TimelineDatesTests {
    private val calendar = parisCalendar()

    private fun day(year: Int, month: Int, day: Int, hour: Int = 0) = calendar.date(year, month, day, hour)

    @Test
    fun endsAtNextMidnightWithoutDueDates() {
        val now = day(2026, 3, 10, hour = 14)

        assertEquals(listOf(now, day(2026, 3, 11)), calendar.timelineDates(now, emptyList()))
    }

    @Test
    fun keepsOnlyDueDatesBeforeNextMidnight() {
        val now = day(2026, 3, 10, hour = 14)
        val laterToday = day(2026, 3, 10, hour = 18)

        val dates = calendar.timelineDates(now, listOf(day(2026, 3, 15), laterToday, day(2026, 3, 10, hour = 9)))

        assertEquals(listOf(now, laterToday, day(2026, 3, 11)), dates)
    }

    @Test
    fun doesNotDuplicateDueDateAtNextMidnight() {
        val now = day(2026, 3, 10, hour = 14)

        assertEquals(listOf(now, day(2026, 3, 11)), calendar.timelineDates(now, listOf(day(2026, 3, 11))))
    }

    @Test
    fun nextMidnightFollowsDaylightSavingChange() {
        val now = day(2026, 10, 25, hour = 1)

        assertEquals(listOf(now, day(2026, 10, 26)), calendar.timelineDates(now, emptyList()))
    }
}
