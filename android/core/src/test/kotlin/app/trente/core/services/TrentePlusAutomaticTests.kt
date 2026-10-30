package app.trente.core.services

import app.trente.core.EUR
import app.trente.core.insertMonth
import app.trente.core.makeStore
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteDates
import app.trente.core.model.TrenteStore
import app.trente.core.services.notifications.RecurringNotificationPlanner
import app.trente.core.services.notifications.RecurringNotificationRequest
import app.trente.core.support.InMemoryKeyValueStore
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TrentePlusAutomaticTests {
    private val calendar = TrenteCalendar.current
    private val service = RecurringTransactionService

    private fun day(year: Int, month: Int, day: Int) = calendar.date(year, month, day)

    private fun insertAutomaticRent(startingOn: Instant, store: TrenteStore): RecurringTransactionRule {
        val rule = RecurringTransactionRule(
            title = "Rent",
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = startingOn,
            autoConfirm = true,
            repartition = mapOf(NEEDS to -800_00),
            createdAt = startingOn
        )
        store.insert(rule)
        return rule
    }

    private fun confirmedDates(store: TrenteStore) = store.transactionGroups.mapNotNull { it.recurringOccurrenceDate }.sorted()

    @Test
    fun lapsedRuleAsksForConfirmation() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertAutomaticRent(day(2025, 4, 2), store)
        store.save()

        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = false)

        assertEquals(0, confirmedCount)
        assertTrue(april.transactionGroups.isEmpty())
        assertEquals(listOf(day(2025, 4, 2)), service.pendingOccurrences(listOf(rule), april).map { it.date })
        assertTrue(rule.autoConfirm)
    }

    @Test
    fun resubscribingIsNotRetroactive() {
        val store = makeStore()
        val months = (1..4).map { insertMonth(2025, it, store) }
        val rule = insertAutomaticRent(day(2025, 1, 2), store)
        store.save()

        service.confirmDueOccurrences(store, now = day(2025, 2, 10), isAutomaticUnlocked = true)
        service.confirmDueOccurrences(store, now = day(2025, 3, 10), isAutomaticUnlocked = false)
        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = true)

        assertEquals(listOf(day(2025, 1, 2), day(2025, 2, 2), day(2025, 4, 2)), confirmedDates(store))
        assertEquals(listOf(day(2025, 3, 2)), service.pendingOccurrences(listOf(rule), months[2]).map { it.date })
    }

    @Test
    fun manualConfirmWhileLapsedIsKept() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertAutomaticRent(day(2025, 4, 2), store)
        store.save()

        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = false)
        service.confirm(service.pendingOccurrences(listOf(rule), april).first(), store)
        val confirmedCount = service.confirmDueOccurrences(store, now = day(2025, 4, 11), isAutomaticUnlocked = true)

        assertEquals(0, confirmedCount)
        assertEquals(1, april.transactionGroups.size)
    }

    @Test
    fun lapsedCatchUpSettles() {
        val store = makeStore()
        insertMonth(2025, 4, store)
        insertAutomaticRent(day(2025, 4, 2), store)
        store.save()
        service.confirmDueOccurrences(store, now = day(2025, 4, 10), isAutomaticUnlocked = false)
        val savesBefore = store.saveCount

        service.confirmDueOccurrences(store, now = day(2025, 4, 11), isAutomaticUnlocked = false)

        assertEquals(0, store.saveCount - savesBefore)
    }

    @Test
    fun lapsedCatchUpStartsMonths() {
        val store = makeStore()
        insertMonth(2025, 3, store)
        insertAutomaticRent(day(2025, 3, 2), store)
        store.save()

        CatchUpService.catchUp(store, now = day(2025, 4, 10), isTrentePlusSubscribed = false)

        assertEquals(listOf(day(2025, 3, 1), day(2025, 4, 1)), store.months.sortedBy { it.startDate }.map { it.startDate })
        assertTrue(confirmedDates(store).isEmpty())
    }

    @Test
    fun lapsedRuleIsAnnouncedAsDue() {
        val store = makeStore()
        val rule = insertAutomaticRent(day(2025, 4, 15), store)
        store.save()
        val planner = RecurringNotificationPlanner(automaticUnlockedUntil = TrenteDates.distantPast)

        val request = planner.requests(listOf(rule), EUR, now = day(2025, 4, 10)).first()

        assertEquals(RecurringNotificationRequest.Kind.DUE, request.kind)
    }

    @Test
    fun endingSubscriptionAnnouncesLaterOnesAsDue() {
        val store = makeStore()
        val rule = insertAutomaticRent(day(2025, 4, 15), store)
        store.save()
        val planner = RecurringNotificationPlanner(automaticUnlockedUntil = day(2025, 5, 1), horizonDays = 60)

        val requests = planner.requests(listOf(rule), EUR, now = day(2025, 4, 10))

        assertEquals(listOf(day(2025, 4, 15), day(2025, 5, 15)), requests.map { it.occurrenceDate })
        assertEquals(
            listOf(RecurringNotificationRequest.Kind.ADDED_AUTOMATICALLY, RecurringNotificationRequest.Kind.DUE),
            requests.map { it.kind }
        )
    }

    @Test
    fun entitlementCache() {
        val defaults = InMemoryKeyValueStore()

        assertFalse(TrentePlusEntitlement.cached(defaults))
        TrentePlusEntitlement.cache(true, defaults)
        assertTrue(TrentePlusEntitlement.cached(defaults))
        TrentePlusEntitlement.cache(false, defaults)
        assertFalse(TrentePlusEntitlement.cached(defaults))
    }
}
