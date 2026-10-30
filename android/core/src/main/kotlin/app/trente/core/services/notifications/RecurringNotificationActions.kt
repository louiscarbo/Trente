package app.trente.core.services.notifications

import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.services.CatchUpService
import app.trente.core.services.MonthService
import app.trente.core.services.RecurringTransactionService
import java.time.Instant
import java.util.UUID

/** The buttons on a due reminder. */
enum class RecurringNotificationAction(val id: String) {
    MARK_AS_PAID("recurring.markAsPaid"),
    SKIP("recurring.skip");

    companion object {
        const val EXPENSE_CATEGORY = "recurring.due"
        const val INCOME_CATEGORY = "recurring.due.income"

        fun fromId(id: String?): RecurringNotificationAction? = entries.firstOrNull { it.id == id }
    }
}

data class RecurringNotificationPayload(val ruleID: UUID, val occurrenceDate: Instant) {
    val userInfo: Map<String, String>
        get() = mapOf(
            RULE_ID_KEY to ruleID.toString(),
            OCCURRENCE_DATE_KEY to occurrenceDate.toEpochMilli().toString()
        )

    companion object {
        const val RULE_ID_KEY = "recurringRuleID"
        const val OCCURRENCE_DATE_KEY = "occurrenceDate"

        fun fromUserInfo(userInfo: Map<String, String>): RecurringNotificationPayload? {
            val ruleID = try {
                UUID.fromString(userInfo[RULE_ID_KEY] ?: return null)
            } catch (exception: IllegalArgumentException) {
                return null
            }
            val timestamp = userInfo[OCCURRENCE_DATE_KEY]?.toLongOrNull() ?: return null
            return RecurringNotificationPayload(ruleID, Instant.ofEpochMilli(timestamp))
        }
    }
}

object RecurringNotificationResponder {
    /** Returns false when the rule is gone or the date isn't one of its pending occurrences. */
    fun handle(
        action: RecurringNotificationAction,
        payload: RecurringNotificationPayload,
        store: TrenteStore,
        now: Instant = Instant.now(),
        isTrentePlusSubscribed: Boolean = false,
        calendar: TrenteCalendar = TrenteCalendar.current
    ): Boolean {
        CatchUpService.catchUp(store, now, isTrentePlusSubscribed, calendar)
        val rule = store.rule(payload.ruleID) ?: return false
        val occurrence = pendingOccurrence(rule, payload.occurrenceDate, store, calendar) ?: return false

        when (action) {
            RecurringNotificationAction.SKIP -> RecurringTransactionService.skip(occurrence, store, calendar)
            RecurringNotificationAction.MARK_AS_PAID -> RecurringTransactionService.confirm(occurrence, store, calendar = calendar)
        }
        return true
    }

    private fun pendingOccurrence(
        rule: RecurringTransactionRule,
        date: Instant,
        store: TrenteStore,
        calendar: TrenteCalendar
    ): RecurringTransactionOccurrence? {
        val month = MonthService.monthContaining(date, store, calendar) ?: return null
        return rule.pendingOccurrences(month, calendar).firstOrNull { calendar.isSameDay(it.date, date) }
    }
}
