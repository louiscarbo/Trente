package app.trente.core.services.notifications

import app.trente.core.model.Currency
import app.trente.core.model.TrenteCalendar
import app.trente.core.support.DateText
import app.trente.core.support.KeyValueStore
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import java.time.Instant
import kotlin.math.abs

/** A local notification to post at `fireDate`. The app turns it into an alarm and a notification. */
data class ScheduledNotification(
    val identifier: String,
    val title: String,
    val body: String,
    val fireDate: Instant,
    val threadIdentifier: String,
    val categoryIdentifier: String? = null,
    val userInfo: Map<String, String> = emptyMap(),
    val prominence: Prominence = Prominence.ALERT
) {
    enum class Prominence { ALERT, PASSIVE }

    companion object {
        fun dayStamp(date: Instant, calendar: TrenteCalendar): String {
            val day = calendar.localDate(date)
            return String.format("%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)
        }
    }
}

data class ReminderTime(val hour: Int, val minute: Int) {
    fun store(defaults: KeyValueStore) {
        defaults.putInt(HOUR_KEY, hour)
        defaults.putInt(MINUTE_KEY, minute)
    }

    fun date(day: Instant, calendar: TrenteCalendar = TrenteCalendar.current): Instant = calendar.withTime(day, hour, minute)

    companion object {
        val STANDARD = ReminderTime(9, 0)
        const val HOUR_KEY = "recurringReminder.hour"
        const val MINUTE_KEY = "recurringReminder.minute"

        fun stored(defaults: KeyValueStore): ReminderTime {
            val hour = defaults.getInt(HOUR_KEY) ?: return STANDARD
            val minute = defaults.getInt(MINUTE_KEY) ?: return STANDARD
            if (hour !in 0..23 || minute !in 0..59) return STANDARD
            return ReminderTime(hour, minute)
        }

        fun from(date: Instant, calendar: TrenteCalendar = TrenteCalendar.current): ReminderTime {
            val zoned = calendar.zoned(date)
            return ReminderTime(zoned.hour, zoned.minute)
        }
    }
}

data class NotificationPreferences(
    val remindsRecurringTransactions: Boolean = true,
    val announcesNewMonths: Boolean = true
) {
    val usesReminderTime: Boolean get() = remindsRecurringTransactions || announcesNewMonths

    fun store(defaults: KeyValueStore) {
        defaults.putBoolean(RECURRING_TRANSACTIONS_KEY, remindsRecurringTransactions)
        defaults.putBoolean(NEW_MONTH_KEY, announcesNewMonths)
    }

    companion object {
        const val RECURRING_TRANSACTIONS_KEY = "notifications.recurringTransactions"
        const val NEW_MONTH_KEY = "notifications.newMonth"

        fun stored(defaults: KeyValueStore) = NotificationPreferences(
            remindsRecurringTransactions = defaults.getBoolean(RECURRING_TRANSACTIONS_KEY) ?: true,
            announcesNewMonths = defaults.getBoolean(NEW_MONTH_KEY) ?: true
        )
    }
}

object NotificationText {
    fun amountTitle(amountCents: Int, currency: Currency, title: String): String {
        val amount = MoneyFormat.amount(abs(amountCents) / 100.0, currency.isoCode)
        return "$amount - $title"
    }

    val goodbyeTitle: String get() = localized("Reminders paused")

    fun goodbyeBody(lastAppOpen: Instant, calendar: TrenteCalendar = TrenteCalendar.current): String {
        val lastOpenDay = DateText.dayMonthWide(calendar.localDate(lastAppOpen))
        return localized("You haven't opened Trente since %@, so reminders are paused. Open the app anytime to turn them back on.", lastOpenDay)
    }
}

/** Keeps only the soonest notifications, within the number of alarms the app is willing to schedule. */
object NotificationScheduling {
    const val SYSTEM_LIMIT = 64

    fun soonest(notifications: List<ScheduledNotification>, limit: Int): List<ScheduledNotification> =
        notifications
            .sortedWith(compareBy<ScheduledNotification> { it.fireDate }.thenBy { it.title })
            .take(maxOf(0, limit))
}
