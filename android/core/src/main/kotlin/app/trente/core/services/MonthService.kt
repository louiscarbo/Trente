package app.trente.core.services

import app.trente.core.model.Month
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import java.time.Instant

object MonthService {
    fun create(month: Month, store: TrenteStore) {
        store.insert(month)
        store.save()
    }

    /** Deleting a month never cascades: its transactions are deleted explicitly. */
    fun delete(month: Month, store: TrenteStore) {
        month.transactionGroups.toList().forEach { store.delete(it) }
        store.delete(month)
    }

    fun latestMonth(store: TrenteStore): Month? = store.months.maxByOrNull { it.startDate }

    fun monthContaining(date: Instant, store: TrenteStore, calendar: TrenteCalendar = TrenteCalendar.current): Month? =
        store.months.sortedByDescending { it.startDate }.firstOrNull { it.contains(date, calendar) }

    /** Starts every month missing up to today, copying the latest month's currency, budget and split. */
    fun createMissingMonths(
        store: TrenteStore,
        now: Instant = Instant.now(),
        calendar: TrenteCalendar = TrenteCalendar.current
    ): List<Month> {
        val latestMonth = latestMonth(store) ?: return emptyList()
        val missingStartDates = startDatesOfMissingMonths(latestMonth.startDate, now, calendar)
        if (missingStartDates.isEmpty()) return emptyList()

        val createdMonths = missingStartDates.map { startDate ->
            Month(
                startDate = startDate,
                currency = latestMonth.currency,
                idealBudgetCents = latestMonth.idealBudgetCents,
                idealRepartition = latestMonth.idealRepartition
            )
        }
        createdMonths.forEach(store::insert)
        store.save()
        return createdMonths
    }

    /** Same arithmetic as `Month.dateInterval`: each missing month starts one month after the previous one. */
    fun startDatesOfMissingMonths(
        latestStartDate: Instant?,
        today: Instant,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): List<Instant> {
        if (latestStartDate == null) return emptyList()
        val missingStartDates = mutableListOf<Instant>()
        var previousStartDate = calendar.startOfDay(latestStartDate)
        while (true) {
            val nextStartDate = calendar.plusMonths(previousStartDate, 1)
            if (nextStartDate > today) break
            missingStartDates.add(nextStartDate)
            previousStartDate = nextStartDate
        }
        return missingStartDates
    }
}

object CatchUpService {
    /** Starts the missing months, then records the automatic transactions due in them. */
    fun catchUp(
        store: TrenteStore,
        now: Instant = Instant.now(),
        isTrentePlusSubscribed: Boolean,
        calendar: TrenteCalendar = TrenteCalendar.current
    ) {
        MonthService.createMissingMonths(store, now, calendar)
        RecurringTransactionService.confirmDueOccurrences(store, now, isAutomaticUnlocked = isTrentePlusSubscribed, calendar = calendar)
    }
}

object ReviewRequestPolicy {
    const val LAST_REQUESTED_VERSION_KEY = "reviewRequest.lastVersion"
    const val LAST_REQUESTED_MONTH_COUNT_KEY = "reviewRequest.lastMonthCount"
    const val FIRST_USE_TIMESTAMP_KEY = "reviewRequest.firstUseTimestamp"

    const val MINIMUM_MONTH_COUNT = 2
    const val MINIMUM_DAYS_OF_USE = 14
    const val DELAY_SECONDS = 3L

    fun shouldRequest(
        monthCount: Int,
        lastRequestedMonthCount: Int,
        lastRequestedVersion: String,
        currentVersion: String,
        firstUseDate: Instant?,
        now: Instant,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): Boolean {
        if (monthCount < MINIMUM_MONTH_COUNT) return false
        if (monthCount <= lastRequestedMonthCount) return false
        if (currentVersion == lastRequestedVersion) return false
        if (firstUseDate == null) return false
        return calendar.daysBetween(firstUseDate, now) >= MINIMUM_DAYS_OF_USE
    }
}
