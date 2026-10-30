package app.trente.core.services.notifications

import app.trente.core.EUR
import app.trente.core.insertMonth
import app.trente.core.makeStore
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.WANTS
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.parisCalendar
import app.trente.core.services.RecurringTransactionService
import app.trente.core.support.DateText
import app.trente.core.support.InMemoryKeyValueStore
import app.trente.core.support.localized
import java.time.Instant
import java.util.UUID
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecurringNotificationPlannerTests {
    private val calendar = parisCalendar()
    private val service = RecurringTransactionService
    private val planner get() = RecurringNotificationPlanner(calendar = calendar)
    private val now get() = day(2025, 4, 10, hour = 8)

    private fun day(year: Int, month: Int, day: Int, hour: Int = 0) = calendar.date(year, month, day, hour)

    private fun insertRule(
        title: String,
        frequency: RecurrenceFrequency = RecurrenceFrequency.MONTHLY,
        startingOn: Instant,
        endingOn: Instant? = null,
        createdAt: Instant? = null,
        repartition: Map<BudgetCategory, Int> = mapOf(NEEDS to -800_00),
        automatic: Boolean = false,
        store: TrenteStore
    ): RecurringTransactionRule {
        val rule = RecurringTransactionRule(
            title = title,
            frequency = frequency,
            startDate = startingOn,
            endDate = endingOn,
            autoConfirm = automatic,
            repartition = repartition,
            createdAt = createdAt ?: startingOn
        )
        store.insert(rule)
        return rule
    }

    private fun occurrence(rule: RecurringTransactionRule, date: Instant, month: Month) =
        RecurringTransactionOccurrence(rule = rule, date = date, month = month)

    @Test
    fun firesAtNineOnTheDueDay() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(1, requests.size)
        val request = requests.first()
        assertEquals(day(2025, 4, 15), request.occurrenceDate)
        assertEquals(day(2025, 4, 15, hour = 9), request.fireDate)
        assertEquals(RecurringNotificationRequest.Kind.DUE, request.kind)
        assertEquals(localized("Due today. Open Trente to mark it as paid."), request.body)
        assertEquals(rule.id, request.ruleID)
    }

    @Test
    fun skipsTodayAfterNine() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        val requests = planner.requests(listOf(rule), EUR, day(2025, 4, 15, hour = 14))

        assertEquals(listOf(day(2025, 5, 15, hour = 9)), requests.map { it.fireDate })
    }

    @Test
    fun usesChosenReminderTime() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()
        val planner = RecurringNotificationPlanner(reminderTime = ReminderTime(18, 30), calendar = calendar)

        val request = planner.requests(listOf(rule), EUR, now).first()

        assertEquals(calendar.date(2025, 4, 15, 18, 30), request.fireDate)
    }

    @Test
    fun neverBeforeRuleCreation() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 40, calendar = calendar)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), createdAt = day(2025, 4, 16), store = store)
        store.save()

        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(listOf(day(2025, 5, 15)), requests.map { it.occurrenceDate })
    }

    @Test
    fun leavesOutSettledOccurrence() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 40, calendar = calendar)
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        service.confirm(occurrence(rule, day(2025, 4, 15), april), store)
        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(listOf(day(2025, 5, 15)), requests.map { it.occurrenceDate })
    }

    @Test
    fun leavesOutSkippedOccurrence() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 40, calendar = calendar)
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        service.skip(occurrence(rule, day(2025, 4, 15), april), store)
        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(listOf(day(2025, 5, 15)), requests.map { it.occurrenceDate })
    }

    @Test
    fun settledPeriodStaysSettledAfterMovingPaymentDay() {
        val store = makeStore()
        val april = insertMonth(2025, 4, store)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 2), store = store)
        store.save()
        service.confirm(occurrence(rule, day(2025, 4, 2), april), store)

        rule.startDate = day(2025, 1, 20)
        store.save()
        val requests = planner.requests(listOf(rule), EUR, now)

        assertTrue(requests.isEmpty())
    }

    @Test
    fun stopsAfterEndDate() {
        val store = makeStore()
        val rule = insertRule(
            "Gym",
            frequency = RecurrenceFrequency.WEEKLY,
            startingOn = day(2025, 4, 1),
            endingOn = day(2025, 4, 22),
            repartition = mapOf(WANTS to -29_00),
            store = store
        )
        store.save()

        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(listOf(day(2025, 4, 15), day(2025, 4, 22)), requests.map { it.occurrenceDate })
    }

    @Test
    fun automaticRuleIsAddedAutomatically() {
        val store = makeStore()
        val rule = insertRule("Netflix", startingOn = day(2025, 1, 15), repartition = mapOf(WANTS to -13_99), automatic = true, store = store)
        store.save()

        val request = planner.requests(listOf(rule), EUR, now).first()

        assertEquals(RecurringNotificationRequest.Kind.ADDED_AUTOMATICALLY, request.kind)
        assertEquals(localized("Added automatically."), request.body)
    }

    @Test
    fun incomeUsesReceivedCopy() {
        val store = makeStore()
        val rule = insertRule("Salary", startingOn = day(2025, 1, 15), repartition = mapOf(NEEDS to 1500_00, WANTS to 500_00), store = store)
        store.save()

        val request = planner.requests(listOf(rule), EUR, now).first()

        assertEquals(RecurringNotificationRequest.Kind.DUE, request.kind)
        assertEquals(localized("Expected today. Open Trente to mark it as received."), request.body)
        assertEquals(NotificationText.amountTitle(2000_00, EUR, "Salary"), request.title)
    }

    @Test
    fun titleUsesAbsoluteAmountAndTitle() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        val request = planner.requests(listOf(rule), EUR, now).first()

        assertEquals(NotificationText.amountTitle(800_00, EUR, "Rent"), request.title)
        assertTrue(request.title.endsWith(" - Rent"))
        assertFalse(request.title.contains("-800"))
    }

    @Test
    fun ignoresDatesBeyondHorizon() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 10, calendar = calendar)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 30), store = store)
        store.save()

        assertTrue(planner.requests(listOf(rule), EUR, now).isEmpty())
    }

    @Test
    fun doesNotNeedAMonth() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 40, calendar = calendar)
        insertMonth(2025, 4, store)
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        store.save()

        val requests = planner.requests(listOf(rule), EUR, now)

        assertEquals(listOf(day(2025, 4, 15), day(2025, 5, 15)), requests.map { it.occurrenceDate })
    }

    @Test
    fun identifierUsesRuleIDAndDay() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)

        val request = planner.requests(listOf(rule), EUR, now).first()

        assertEquals("recurring.${rule.id.toString().uppercase()}.2025-04-15", request.identifier)
    }

    @Test
    fun buttonsDoNotNeedAMonth() {
        val store = makeStore()
        val planner = RecurringNotificationPlanner(horizonDays = 40, calendar = calendar)
        insertMonth(2025, 4, store)
        val rent = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)

        val notifications = planner.requests(listOf(rent), EUR, now).map { it.scheduledNotification }

        assertEquals(
            listOf(RecurringNotificationAction.EXPENSE_CATEGORY, RecurringNotificationAction.EXPENSE_CATEGORY),
            notifications.map { it.categoryIdentifier }
        )
    }

    @Test
    fun incomeIsFlagged() {
        val store = makeStore()
        val rule = insertRule("Salary", startingOn = day(2025, 1, 15), repartition = mapOf(NEEDS to 1000_00), store = store)

        assertTrue(planner.requests(listOf(rule), EUR, now).first().isIncome)
    }

    @Test
    fun scheduledNotificationCarriesCategoryAndProminence() {
        val store = makeStore()
        val rent = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        val salary = insertRule("Salary", startingOn = day(2025, 1, 20), repartition = mapOf(NEEDS to 1000_00), store = store)
        val netflix = insertRule("Netflix", startingOn = day(2025, 1, 25), repartition = mapOf(WANTS to -13_99), automatic = true, store = store)

        val notifications = planner.requests(listOf(rent, salary, netflix), EUR, now).map { it.scheduledNotification }

        assertEquals(
            listOf(RecurringNotificationAction.EXPENSE_CATEGORY, RecurringNotificationAction.INCOME_CATEGORY, null),
            notifications.map { it.categoryIdentifier }
        )
        assertEquals(
            listOf(ScheduledNotification.Prominence.ALERT, ScheduledNotification.Prominence.ALERT, ScheduledNotification.Prominence.PASSIVE),
            notifications.map { it.prominence }
        )
        val payload = RecurringNotificationPayload.fromUserInfo(notifications[0].userInfo)
        assertEquals(RecurringNotificationPayload(rent.id, day(2025, 4, 15)), payload)
    }

    @Test
    fun disabledRemindsNothing() {
        val store = makeStore()
        val rule = insertRule("Rent", startingOn = day(2025, 1, 15), store = store)
        val planner = RecurringNotificationPlanner(isEnabled = false, calendar = calendar)

        assertTrue(planner.requests(listOf(rule), EUR, now).isEmpty())
    }
}

class NewMonthNotificationPlannerTests {
    private val calendar = parisCalendar()
    private val planner get() = NewMonthNotificationPlanner(calendar = calendar)

    private fun day(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) = calendar.date(year, month, day, hour, minute)

    @Test
    fun announcesNextThreeMonths() {
        val requests = planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 10, 10))

        assertEquals(listOf(day(2025, 11, 1), day(2025, 12, 1), day(2026, 1, 1)), requests.map { it.startDate })
        assertEquals(
            listOf(day(2025, 11, 1, 9), day(2025, 12, 1, 9), day(2026, 1, 1, 9)),
            requests.map { it.fireDate }
        )
    }

    @Test
    fun followsStartDay() {
        val requests = planner.requests(latestStartDate = day(2025, 10, 25), now = day(2025, 10, 26))

        assertEquals(day(2025, 11, 25), requests.first().startDate)
    }

    @Test
    fun usesReminderTime() {
        val planner = NewMonthNotificationPlanner(reminderTime = ReminderTime(7, 45), calendar = calendar)

        val request = planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 10, 10)).first()

        assertEquals(day(2025, 11, 1, 7, 45), request.fireDate)
    }

    @Test
    fun skipsPassedReminder() {
        val requests = planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 11, 1, hour = 10))

        assertEquals(day(2025, 12, 1), requests.first().startDate)
        assertEquals(3, requests.size)
    }

    @Test
    fun titleNamesMonth() {
        val request = planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 10, 10)).first()

        assertEquals(NewMonthNotificationPlanner.title(day(2025, 11, 1), calendar), request.title)
        assertTrue(request.title.contains(Month.name(day(2025, 11, 1), calendar)))
        assertEquals(NewMonthNotificationPlanner.body, request.body)
    }

    @Test
    fun identifierUsesStartDay() {
        val request = planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 10, 10)).first()

        assertEquals("newMonth.2025-11-01", request.identifier)
    }

    @Test
    fun disabledAnnouncesNothing() {
        val planner = NewMonthNotificationPlanner(isEnabled = false, calendar = calendar)

        assertTrue(planner.requests(latestStartDate = day(2025, 10, 1), now = day(2025, 10, 10)).isEmpty())
    }
}

class InactivityNotificationPlannerTests {
    private val calendar = parisCalendar()
    private val planner get() = InactivityNotificationPlanner(calendar = calendar)

    private fun day(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) = calendar.date(year, month, day, hour, minute)

    private fun reminder(identifier: String, firingAt: Instant) = ScheduledNotification(
        identifier = identifier,
        title = identifier,
        body = "",
        fireDate = firingAt,
        threadIdentifier = "test"
    )

    @Test
    fun goodbyeAWeekLater() {
        assertEquals(day(2026, 11, 3, 9), planner.goodbyeDate(lastAppOpen = day(2026, 10, 27, 20)))
    }

    @Test
    fun goodbyeUsesReminderTime() {
        val planner = InactivityNotificationPlanner(reminderTime = ReminderTime(18, 30), calendar = calendar)

        assertEquals(day(2026, 11, 3, 18, 30), planner.goodbyeDate(lastAppOpen = day(2026, 10, 27, 8)))
    }

    @Test
    fun dropsRemindersAfterGoodbye() {
        val reminders = listOf(
            reminder("tomorrow", day(2026, 10, 28, 9)),
            reminder("sixDays", day(2026, 11, 2, 9)),
            reminder("sameTimeAsGoodbye", day(2026, 11, 3, 9)),
            reminder("nextMonth", day(2026, 11, 25, 9))
        )

        val notifications = planner.notifications(keeping = reminders, lastAppOpen = day(2026, 10, 27, 12))

        assertEquals(listOf("tomorrow", "sixDays", InactivityNotificationPlanner.GOODBYE_IDENTIFIER), notifications.map { it.identifier })
        assertEquals(day(2026, 11, 3, 9), notifications.last().fireDate)
    }

    @Test
    fun goodbyeWithoutReminders() {
        val reminders = listOf(reminder("nextMonth", day(2026, 11, 25, 9)))

        val withoutReminders = planner.notifications(keeping = emptyList(), lastAppOpen = day(2026, 10, 27))
        val withLaterReminder = planner.notifications(keeping = reminders, lastAppOpen = day(2026, 10, 27))

        assertEquals(listOf(InactivityNotificationPlanner.GOODBYE_IDENTIFIER), withoutReminders.map { it.identifier })
        assertEquals(listOf(InactivityNotificationPlanner.GOODBYE_IDENTIFIER), withLaterReminder.map { it.identifier })
    }

    @Test
    fun reopeningMovesCutoff() {
        val reminders = listOf(
            reminder("tomorrow", day(2026, 10, 28, 9)),
            reminder("inTenDays", day(2026, 11, 6, 9))
        )

        val beforeReopening = planner.notifications(keeping = reminders, lastAppOpen = day(2026, 10, 27, 12))
        val afterReopening = planner.notifications(keeping = reminders, lastAppOpen = day(2026, 10, 31, 12))

        assertEquals(listOf("tomorrow", InactivityNotificationPlanner.GOODBYE_IDENTIFIER), beforeReopening.map { it.identifier })
        assertEquals(listOf("tomorrow", "inTenDays", InactivityNotificationPlanner.GOODBYE_IDENTIFIER), afterReopening.map { it.identifier })
        assertEquals(day(2026, 11, 7, 9), afterReopening.last().fireDate)
    }

    @Test
    fun goodbyeContent() {
        val lastAppOpen = day(2026, 10, 27, 12)
        val goodbye = InactivityNotificationPlanner.goodbye(fireDate = day(2026, 11, 3, 9), lastAppOpen = lastAppOpen, calendar = calendar)

        assertEquals(NotificationText.goodbyeTitle, goodbye.title)
        assertEquals(NotificationText.goodbyeBody(lastAppOpen, calendar), goodbye.body)
        assertTrue(goodbye.body.contains(DateText.dayMonthWide(calendar.localDate(lastAppOpen))))
        assertNull(goodbye.categoryIdentifier)
        assertFalse(goodbye.identifier.startsWith(RecurringNotificationPlanner.IDENTIFIER_PREFIX))
    }

    @Test
    fun lastAppOpenRoundTrip() {
        val defaults = InMemoryKeyValueStore()
        val openedAt = day(2026, 10, 27, 8)

        assertNull(InactivityNotificationPlanner.storedLastAppOpen(defaults))
        InactivityNotificationPlanner.recordAppOpen(openedAt, defaults)
        assertEquals(openedAt, InactivityNotificationPlanner.storedLastAppOpen(defaults))
    }
}

class ReminderTimeTests {
    private val calendar = parisCalendar()

    @Test
    fun defaultsToNine() {
        assertEquals(ReminderTime(9, 0), ReminderTime.stored(InMemoryKeyValueStore()))
    }

    @Test
    fun roundTrip() {
        val defaults = InMemoryKeyValueStore()
        ReminderTime(7, 30).store(defaults)

        assertEquals(ReminderTime(7, 30), ReminderTime.stored(defaults))
    }

    @Test
    fun invalidFallsBack() {
        for ((hour, minute) in listOf(24 to 0, -1 to 0, 9 to 60)) {
            val defaults = InMemoryKeyValueStore()
            defaults.putInt(ReminderTime.HOUR_KEY, hour)
            defaults.putInt(ReminderTime.MINUTE_KEY, minute)

            assertEquals(ReminderTime.STANDARD, ReminderTime.stored(defaults))
        }
    }

    @Test
    fun dateOnDay() {
        val day = calendar.date(2025, 4, 15)

        assertEquals(calendar.date(2025, 4, 15, 18, 45), ReminderTime(18, 45).date(day, calendar))
    }

    @Test
    fun fromDate() {
        val picked = calendar.date(2030, 1, 2, 6, 5)

        assertEquals(ReminderTime(6, 5), ReminderTime.from(picked, calendar))
    }
}

class NotificationSchedulerTests {
    private val now = Instant.EPOCH

    private fun notification(identifier: String, title: String = "", inHours: Double) = ScheduledNotification(
        identifier = identifier,
        title = title,
        body = "",
        fireDate = now.plusSeconds((inHours * 3600).toLong()),
        threadIdentifier = "test"
    )

    @Test
    fun keepsTheSoonestUpToTheLimit() {
        val notifications = listOf(
            notification("later", inHours = 30.0),
            notification("soonest", inHours = 1.0),
            notification("dropped", inHours = 50.0),
            notification("soon", inHours = 5.0)
        )

        val kept = NotificationScheduling.soonest(notifications, limit = 3)

        assertEquals(listOf("soonest", "soon", "later"), kept.map { it.identifier })
    }

    @Test
    fun tiesAreOrderedByTitle() {
        val notifications = listOf(
            notification("gym", title = "Gym", inHours = 1.0),
            notification("bakery", title = "Bakery", inHours = 1.0)
        )

        val kept = NotificationScheduling.soonest(notifications, limit = 64)

        assertEquals(listOf("bakery", "gym"), kept.map { it.identifier })
    }
}

class NotificationPreferencesTests {
    @Test
    fun defaultsToOn() {
        assertEquals(NotificationPreferences(remindsRecurringTransactions = true, announcesNewMonths = true), NotificationPreferences.stored(InMemoryKeyValueStore()))
    }

    @Test
    fun readsStoredChoices() {
        val defaults = InMemoryKeyValueStore()
        defaults.putBoolean(NotificationPreferences.RECURRING_TRANSACTIONS_KEY, false)
        defaults.putBoolean(NotificationPreferences.NEW_MONTH_KEY, true)

        assertEquals(NotificationPreferences(remindsRecurringTransactions = false, announcesNewMonths = true), NotificationPreferences.stored(defaults))
    }

    @Test
    fun usesReminderTime() {
        for ((recurring, newMonth, expected) in listOf(
            Triple(true, true, true),
            Triple(true, false, true),
            Triple(false, true, true),
            Triple(false, false, false)
        )) {
            assertEquals(expected, NotificationPreferences(recurring, newMonth).usesReminderTime)
        }
    }
}

class RecurringNotificationResponderTests {
    private val calendar = TrenteCalendar.current

    private fun day(year: Int, month: Int, day: Int) = calendar.date(year, month, day)

    private fun insertRule(title: String, repartition: Map<BudgetCategory, Int> = mapOf(NEEDS to -800_00), store: TrenteStore): RecurringTransactionRule {
        val rule = RecurringTransactionRule(
            title = title,
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = day(2026, 1, 15),
            repartition = repartition,
            createdAt = day(2026, 1, 1)
        )
        store.insert(rule)
        return rule
    }

    @Test
    fun payloadRoundTrip() {
        val payload = RecurringNotificationPayload(UUID.randomUUID(), day(2026, 10, 15))

        assertEquals(payload, RecurringNotificationPayload.fromUserInfo(payload.userInfo))
    }

    @Test
    fun foreignUserInfo() {
        assertNull(RecurringNotificationPayload.fromUserInfo(mapOf("pendingTransactionID" to UUID.randomUUID().toString())))
    }

    @Test
    fun markAsPaidRecordsTransaction() {
        val store = makeStore()
        val october = insertMonth(2026, 10, store)
        val rule = insertRule("Rent", store = store)
        store.save()
        val payload = RecurringNotificationPayload(rule.id, day(2026, 10, 15))

        val handled = RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store)

        assertTrue(handled)
        val group = store.transactionGroups.first()
        assertEquals(october.id, group.month?.id)
        assertEquals(rule.id, group.recurringRule?.id)
        assertEquals(day(2026, 10, 15), group.recurringOccurrenceDate)
        assertEquals(-800_00, group.totalAmountCents)
    }

    @Test
    fun markAsPaidTwice() {
        val store = makeStore()
        insertMonth(2026, 10, store)
        val rule = insertRule("Rent", store = store)
        store.save()
        val payload = RecurringNotificationPayload(rule.id, day(2026, 10, 15))

        RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store)
        RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store)

        assertEquals(1, store.transactionGroups.size)
    }

    @Test
    fun skipMarksOccurrence() {
        val store = makeStore()
        insertMonth(2026, 10, store)
        val rule = insertRule("Rent", store = store)
        store.save()
        val payload = RecurringNotificationPayload(rule.id, day(2026, 10, 15))

        val handled = RecurringNotificationResponder.handle(RecurringNotificationAction.SKIP, payload, store)

        assertTrue(handled)
        assertTrue(rule.isSkipped(day(2026, 10, 15)))
        assertTrue(store.transactionGroups.isEmpty())
    }

    @Test
    fun markAsPaidStartsMissingMonth() {
        val store = makeStore()
        insertMonth(2026, 9, store)
        val rule = insertRule("Rent", store = store)
        store.save()
        val payload = RecurringNotificationPayload(rule.id, day(2026, 10, 15))

        val handled = RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store, now = day(2026, 10, 15))

        assertTrue(handled)
        val group = store.transactionGroups.first()
        assertEquals(day(2026, 10, 1), group.month?.startDate)
        assertEquals(day(2026, 10, 15), group.recurringOccurrenceDate)
    }

    @Test
    fun dateOutsideScheduleIsIgnored() {
        val store = makeStore()
        insertMonth(2026, 10, store)
        val rule = insertRule("Rent", store = store)
        store.save()
        val payload = RecurringNotificationPayload(rule.id, day(2026, 10, 16))

        val handled = RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store)

        assertFalse(handled)
        assertTrue(store.transactionGroups.isEmpty())
    }

    @Test
    fun deletedRuleIsIgnored() {
        val store = makeStore()
        insertMonth(2026, 10, store)
        val payload = RecurringNotificationPayload(UUID.randomUUID(), day(2026, 10, 15))

        assertFalse(RecurringNotificationResponder.handle(RecurringNotificationAction.MARK_AS_PAID, payload, store))
    }

    @Test
    fun clearsOnlySettledReminders() {
        val store = makeStore()
        val october = insertMonth(2026, 10, store)
        fun makeRule(title: String, startingOn: Instant, amountCents: Int) = RecurringTransactionRule(
            title = title,
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = startingOn,
            repartition = mapOf(NEEDS to amountCents),
            createdAt = day(2026, 1, 1)
        )
        val rent = makeRule("Rent", day(2026, 1, 15), -800_00)
        val gym = makeRule("Gym", day(2026, 1, 20), -30_00)
        val phone = makeRule("Phone", day(2026, 1, 5), -20_00)
        listOf(rent, gym, phone).forEach { store.insert(it) }
        store.save()
        RecurringTransactionService.confirm(RecurringTransactionOccurrence(rent, day(2026, 10, 15), october), store)
        RecurringTransactionService.skip(RecurringTransactionOccurrence(gym, day(2026, 10, 20), october), store)
        val delivered = listOf(
            DeliveredNotification("rent", RecurringNotificationPayload(rent.id, day(2026, 10, 15))),
            DeliveredNotification("gym", RecurringNotificationPayload(gym.id, day(2026, 10, 20))),
            DeliveredNotification("phone", RecurringNotificationPayload(phone.id, day(2026, 10, 5))),
            DeliveredNotification("deleted", RecurringNotificationPayload(UUID.randomUUID(), day(2026, 10, 5)))
        )

        val cleared = RecurringNotificationPlanner().identifiersToClear(delivered, listOf(rent, gym, phone))

        assertEquals(listOf("rent", "gym", "deleted"), cleared)
        assertNotNull(cleared)
    }
}
