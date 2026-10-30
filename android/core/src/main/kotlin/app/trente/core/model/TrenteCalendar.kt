package app.trente.core.model

import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit
import java.time.temporal.WeekFields
import java.util.Locale

/** A half-open range of instants: `start` is included, `end` is not. */
data class DateInterval(val start: Instant, val end: Instant) {
    val isEmpty: Boolean get() = end <= start

    operator fun contains(date: Instant): Boolean = start <= date && date < end
}

object TrenteDates {
    val distantPast: Instant = Instant.parse("0001-01-01T00:00:00Z")
    val distantFuture: Instant = Instant.parse("4000-01-01T00:00:00Z")
}

enum class DateGranularity { DAY, WEEK, MONTH, YEAR }

/**
 * Day arithmetic in one time zone, standing in for Foundation's `Calendar`.
 *
 * Every date Trente stores is an [Instant]; this is where instants become days, weeks and months.
 */
class TrenteCalendar(
    val zone: ZoneId = ZoneId.systemDefault(),
    val locale: Locale = Locale.getDefault()
) {
    companion object {
        /** The device's time zone and locale, read each time so changes are picked up. */
        val current: TrenteCalendar get() = TrenteCalendar()
    }

    private val weekFields: WeekFields = WeekFields.of(locale)

    fun zoned(instant: Instant): ZonedDateTime = instant.atZone(zone)

    fun localDate(instant: Instant): LocalDate = zoned(instant).toLocalDate()

    fun instant(date: LocalDate): Instant = date.atStartOfDay(zone).toInstant()

    fun startOfDay(instant: Instant): Instant = instant(localDate(instant))

    fun date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0): Instant =
        LocalDateTime.of(year, month, day, hour, minute).atZone(zone).toInstant()

    fun withTime(instant: Instant, hour: Int, minute: Int): Instant =
        zoned(instant).withHour(hour).withMinute(minute).withSecond(0).withNano(0).toInstant()

    fun plusDays(instant: Instant, days: Long): Instant = zoned(instant).plusDays(days).toInstant()

    fun plusWeeks(instant: Instant, weeks: Long): Instant = zoned(instant).plusWeeks(weeks).toInstant()

    fun plusMonths(instant: Instant, months: Long): Instant = zoned(instant).plusMonths(months).toInstant()

    fun plusYears(instant: Instant, years: Long): Instant = zoned(instant).plusYears(years).toInstant()

    fun plus(instant: Instant, unit: ChronoUnit, amount: Long): Instant = zoned(instant).plus(amount, unit).toInstant()

    /** Whole calendar days between the days of both instants, like `dateComponents([.day])` on two start-of-days. */
    fun daysBetween(from: Instant, to: Instant): Long = ChronoUnit.DAYS.between(localDate(from), localDate(to))

    fun wholeUnitsBetween(from: Instant, to: Instant, unit: ChronoUnit): Long = unit.between(zoned(from), zoned(to))

    fun isSame(first: Instant, second: Instant, granularity: DateGranularity): Boolean {
        val lhs = zoned(first)
        val rhs = zoned(second)
        return when (granularity) {
            DateGranularity.DAY -> lhs.toLocalDate() == rhs.toLocalDate()
            DateGranularity.WEEK ->
                lhs.get(weekFields.weekBasedYear()) == rhs.get(weekFields.weekBasedYear()) &&
                    lhs.get(weekFields.weekOfWeekBasedYear()) == rhs.get(weekFields.weekOfWeekBasedYear())
            DateGranularity.MONTH -> lhs.year == rhs.year && lhs.month == rhs.month
            DateGranularity.YEAR -> lhs.year == rhs.year
        }
    }

    fun isSameDay(first: Instant, second: Instant): Boolean = isSame(first, second, DateGranularity.DAY)

    /** The widget timeline: now, every due date before the next midnight, and that midnight. */
    fun timelineDates(now: Instant, dueDates: List<Instant>): List<Instant> {
        val nextMidnight = startOfDay(plusDays(now, 1))
        val dueBeforeMidnight = dueDates.filter { it >= now && it <= nextMidnight }
        return (listOf(now, nextMidnight) + dueBeforeMidnight).toSortedSet().toList()
    }
}

val RecurrenceFrequency.chronoUnit: ChronoUnit
    get() = when (this) {
        RecurrenceFrequency.WEEKLY -> ChronoUnit.WEEKS
        RecurrenceFrequency.MONTHLY -> ChronoUnit.MONTHS
        RecurrenceFrequency.YEARLY -> ChronoUnit.YEARS
    }

val RecurrenceFrequency.granularity: DateGranularity
    get() = when (this) {
        RecurrenceFrequency.WEEKLY -> DateGranularity.WEEK
        RecurrenceFrequency.MONTHLY -> DateGranularity.MONTH
        RecurrenceFrequency.YEARLY -> DateGranularity.YEAR
    }
