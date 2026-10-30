package app.trente.core.services.notifications

import app.trente.core.model.Currency
import app.trente.core.model.DateInterval
import app.trente.core.model.Month
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteDates
import app.trente.core.support.KeyValueStore
import app.trente.core.support.localized
import java.time.Instant
import java.util.UUID

data class RecurringNotificationRequest(
    val identifier: String,
    val ruleID: UUID,
    val occurrenceDate: Instant,
    val fireDate: Instant,
    val kind: Kind,
    val isIncome: Boolean,
    val title: String,
    val body: String
) {
    enum class Kind { DUE, ADDED_AUTOMATICALLY }

    val scheduledNotification: ScheduledNotification
        get() = ScheduledNotification(
            identifier = identifier,
            title = title,
            body = body,
            fireDate = fireDate,
            threadIdentifier = RecurringNotificationPlanner.THREAD_IDENTIFIER,
            categoryIdentifier = categoryIdentifier,
            userInfo = RecurringNotificationPayload(ruleID, occurrenceDate).userInfo,
            prominence = if (kind == Kind.DUE) ScheduledNotification.Prominence.ALERT else ScheduledNotification.Prominence.PASSIVE
        )

    private val categoryIdentifier: String?
        get() {
            if (kind != Kind.DUE) return null
            return if (isIncome) RecurringNotificationAction.INCOME_CATEGORY else RecurringNotificationAction.EXPENSE_CATEGORY
        }
}

/** A reminder that was shown and may need clearing once its occurrence is settled. */
data class DeliveredNotification(val identifier: String, val payload: RecurringNotificationPayload)

data class RecurringNotificationPlanner(
    val isEnabled: Boolean = true,
    val automaticUnlockedUntil: Instant = TrenteDates.distantFuture,
    val horizonDays: Int = 35,
    val reminderTime: ReminderTime = ReminderTime.STANDARD,
    val calendar: TrenteCalendar = TrenteCalendar.current
) {
    fun requests(rules: List<RecurringTransactionRule>, currency: Currency, now: Instant): List<RecurringNotificationRequest> {
        if (!isEnabled) return emptyList()
        val start = calendar.startOfDay(now)
        val window = DateInterval(start, calendar.plusDays(start, horizonDays.toLong()))
        return rules.flatMap { requests(it, window, currency, now) }
    }

    private fun requests(
        rule: RecurringTransactionRule,
        window: DateInterval,
        currency: Currency,
        now: Instant
    ): List<RecurringNotificationRequest> {
        val amountCents = rule.amountCents
        val title = NotificationText.amountTitle(amountCents, currency, rule.title)
        val isIncome = amountCents > 0

        return rule.schedule.dates(window, calendar).mapNotNull { date ->
            if (!rule.isPending(date, calendar)) return@mapNotNull null
            val fireDate = reminderTime.date(date, calendar)
            if (fireDate <= now) return@mapNotNull null

            val isAddedAutomatically = rule.autoConfirm && fireDate < automaticUnlockedUntil
            val kind = if (isAddedAutomatically) RecurringNotificationRequest.Kind.ADDED_AUTOMATICALLY else RecurringNotificationRequest.Kind.DUE
            RecurringNotificationRequest(
                identifier = identifier(rule.id, date),
                ruleID = rule.id,
                occurrenceDate = date,
                fireDate = fireDate,
                kind = kind,
                isIncome = isIncome,
                title = title,
                body = body(kind, isIncome)
            )
        }
    }

    /** The shown reminders whose occurrence is paid, skipped or whose rule is gone. */
    fun identifiersToClear(delivered: List<DeliveredNotification>, rules: List<RecurringTransactionRule>): List<String> =
        delivered.mapNotNull { notification ->
            val rule = rules.firstOrNull { it.id == notification.payload.ruleID } ?: return@mapNotNull notification.identifier
            if (rule.isPending(notification.payload.occurrenceDate, calendar)) null else notification.identifier
        }

    private fun identifier(ruleID: UUID, date: Instant): String =
        "$IDENTIFIER_PREFIX${ruleID.toString().uppercase()}.${ScheduledNotification.dayStamp(date, calendar)}"

    companion object {
        const val IDENTIFIER_PREFIX = "recurring."
        const val THREAD_IDENTIFIER = "recurring"

        fun body(kind: RecurringNotificationRequest.Kind, isIncome: Boolean): String = when {
            kind == RecurringNotificationRequest.Kind.DUE && isIncome -> localized("Expected today. Open Trente to mark it as received.")
            kind == RecurringNotificationRequest.Kind.DUE -> localized("Due today. Open Trente to mark it as paid.")
            else -> localized("Added automatically.")
        }
    }
}

data class NewMonthNotificationRequest(
    val identifier: String,
    val startDate: Instant,
    val fireDate: Instant,
    val title: String,
    val body: String
) {
    val scheduledNotification: ScheduledNotification
        get() = ScheduledNotification(
            identifier = identifier,
            title = title,
            body = body,
            fireDate = fireDate,
            threadIdentifier = NewMonthNotificationPlanner.THREAD_IDENTIFIER
        )
}

data class NewMonthNotificationPlanner(
    val isEnabled: Boolean = true,
    val count: Int = 3,
    val reminderTime: ReminderTime = ReminderTime.STANDARD,
    val calendar: TrenteCalendar = TrenteCalendar.current
) {
    private val maximumMonthsAhead = 1200

    fun requests(latestStartDate: Instant, now: Instant): List<NewMonthNotificationRequest> {
        if (!isEnabled) return emptyList()
        val requests = mutableListOf<NewMonthNotificationRequest>()
        var startDate = calendar.startOfDay(latestStartDate)
        var monthsAhead = 0
        while (requests.size < count && monthsAhead < maximumMonthsAhead) {
            startDate = calendar.plusMonths(startDate, 1)
            monthsAhead += 1
            val fireDate = reminderTime.date(startDate, calendar)
            if (fireDate <= now) continue
            requests.add(
                NewMonthNotificationRequest(
                    identifier = "$IDENTIFIER_PREFIX${ScheduledNotification.dayStamp(startDate, calendar)}",
                    startDate = startDate,
                    fireDate = fireDate,
                    title = title(startDate, calendar),
                    body = body
                )
            )
        }
        return requests
    }

    companion object {
        const val IDENTIFIER_PREFIX = "newMonth."
        const val THREAD_IDENTIFIER = "newMonth"

        fun title(startDate: Instant, calendar: TrenteCalendar = TrenteCalendar.current): String =
            localized("%@ starts today", Month.name(startDate, calendar))

        val body: String
            get() = localized("Your new month is ready, with the same budget as last month. Open Trente to see it.")
    }
}

data class InactivityNotificationPlanner(
    val reminderTime: ReminderTime = ReminderTime.STANDARD,
    val calendar: TrenteCalendar = TrenteCalendar.current
) {
    fun goodbyeDate(lastAppOpen: Instant): Instant? {
        val lastOpenDay = calendar.startOfDay(lastAppOpen)
        val goodbyeDay = calendar.plusDays(lastOpenDay, DAYS_BEFORE_GOODBYE.toLong())
        return reminderTime.date(goodbyeDay, calendar)
    }

    /** Drops the reminders after the goodbye and adds the goodbye last. */
    fun notifications(keeping: List<ScheduledNotification>, lastAppOpen: Instant): List<ScheduledNotification> {
        val goodbyeDate = goodbyeDate(lastAppOpen) ?: return keeping
        val keptReminders = keeping.filter { it.fireDate < goodbyeDate }
        return keptReminders + goodbye(goodbyeDate, lastAppOpen, calendar)
    }

    companion object {
        const val DAYS_BEFORE_GOODBYE = 7
        const val GOODBYE_IDENTIFIER = "inactivity.goodbye"
        const val THREAD_IDENTIFIER = "inactivity"
        const val LAST_APP_OPEN_KEY = "notifications.lastAppOpen"

        fun storedLastAppOpen(defaults: KeyValueStore): Instant? = defaults.getLong(LAST_APP_OPEN_KEY)?.let(Instant::ofEpochMilli)

        fun recordAppOpen(at: Instant = Instant.now(), defaults: KeyValueStore) {
            defaults.putLong(LAST_APP_OPEN_KEY, at.toEpochMilli())
        }

        fun goodbye(fireDate: Instant, lastAppOpen: Instant, calendar: TrenteCalendar = TrenteCalendar.current) = ScheduledNotification(
            identifier = GOODBYE_IDENTIFIER,
            title = NotificationText.goodbyeTitle,
            body = NotificationText.goodbyeBody(lastAppOpen, calendar),
            fireDate = fireDate,
            threadIdentifier = THREAD_IDENTIFIER
        )
    }
}
