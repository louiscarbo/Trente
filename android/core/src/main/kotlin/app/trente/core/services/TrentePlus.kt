package app.trente.core.services

import app.trente.core.support.KeyValueStore
import java.time.Instant

/** The state of a subscription, as reported by the store. */
enum class SubscriptionState {
    SUBSCRIBED,
    IN_GRACE_PERIOD,
    EXPIRED,
    REVOKED,
    IN_BILLING_RETRY_PERIOD
}

object TrentePlus {
    /** The Google Play subscription product and its two base plans. Configure them in the Play Console with these ids. */
    const val PRODUCT_ID = "trente_plus"
    const val MONTHLY_PLAN_ID = "monthly"
    const val YEARLY_PLAN_ID = "yearly"

    data class Renewal(val willAutoRenew: Boolean, val expirationDate: Instant?)

    /** Only a subscription that is active or in its grace period unlocks Trente+. */
    fun isActive(states: List<SubscriptionState>): Boolean =
        states.any { it == SubscriptionState.SUBSCRIBED || it == SubscriptionState.IN_GRACE_PERIOD }

    /** No end date while any subscription renews; otherwise Trente+ ends with the latest one. */
    fun endDate(renewals: List<Renewal>): Instant? {
        if (renewals.any { it.willAutoRenew }) return null
        return renewals.mapNotNull { it.expirationDate }.maxOrNull()
    }
}

/** The last known status, kept for the widget and for launch, before the store answers. */
object TrentePlusEntitlement {
    const val KEY = "trentePlus.isSubscribed"

    fun cached(defaults: KeyValueStore): Boolean = defaults.getBoolean(KEY) ?: false

    fun cache(isSubscribed: Boolean, defaults: KeyValueStore) {
        defaults.putBoolean(KEY, isSubscribed)
    }
}

/** Debug builds can pretend to be subscribed or not. */
enum class TrentePlusDebugOverride(val rawValue: String) {
    STORE("appStore"),
    SUBSCRIBED("subscribed"),
    NOT_SUBSCRIBED("notSubscribed");

    fun store(defaults: KeyValueStore) {
        defaults.putString(KEY, rawValue)
    }

    fun isSubscribed(hasActiveSubscription: Boolean): Boolean = when (this) {
        STORE -> hasActiveSubscription
        SUBSCRIBED -> true
        NOT_SUBSCRIBED -> false
    }

    companion object {
        const val KEY = "debug.trentePlusOverride"

        fun stored(defaults: KeyValueStore): TrentePlusDebugOverride =
            defaults.getString(KEY)?.let { raw -> entries.firstOrNull { it.rawValue == raw } } ?: STORE
    }
}
