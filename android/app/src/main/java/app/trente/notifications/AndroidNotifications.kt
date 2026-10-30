package app.trente.notifications

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import app.trente.AppContainer
import app.trente.MainActivity
import app.trente.R
import app.trente.appContainer
import app.trente.core.services.MonthService
import app.trente.core.services.notifications.DeliveredNotification
import app.trente.core.services.notifications.InactivityNotificationPlanner
import app.trente.core.services.notifications.NewMonthNotificationPlanner
import app.trente.core.services.notifications.NotificationPreferences
import app.trente.core.services.notifications.NotificationScheduling
import app.trente.core.services.notifications.RecurringNotificationAction
import app.trente.core.services.notifications.RecurringNotificationPayload
import app.trente.core.services.notifications.RecurringNotificationPlanner
import app.trente.core.services.notifications.RecurringNotificationResponder
import app.trente.core.services.notifications.ReminderTime
import app.trente.core.services.notifications.ScheduledNotification
import app.trente.core.support.KeyValueStore
import app.trente.core.support.NotificationAuthorizing
import app.trente.core.support.NotificationPermissionStatus
import app.trente.core.support.localized
import java.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

object TrenteNotifications {
    const val CHANNEL_RECURRING = "recurring"
    const val CHANNEL_NEW_MONTH = "newMonth"
    const val CHANNEL_INACTIVITY = "inactivity"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_RECURRING, localized("Recurring Transactions"), NotificationManager.IMPORTANCE_DEFAULT)
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_NEW_MONTH, localized("New Month"), NotificationManager.IMPORTANCE_DEFAULT)
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_INACTIVITY, localized("Reminders paused"), NotificationManager.IMPORTANCE_LOW)
        )
    }

    fun channel(threadIdentifier: String): String = when (threadIdentifier) {
        NewMonthNotificationPlanner.THREAD_IDENTIFIER -> CHANNEL_NEW_MONTH
        InactivityNotificationPlanner.THREAD_IDENTIFIER -> CHANNEL_INACTIVITY
        else -> CHANNEL_RECURRING
    }
}

/** The notification permission as Android exposes it. The activity registers the launcher that asks. */
class AndroidNotificationCenter(private val context: Context, private val preferences: KeyValueStore) : NotificationAuthorizing {
    /** Set by the activity: shows the system dialog and returns the answer. */
    var requester: (suspend () -> Boolean)? = null

    override suspend fun currentStatus(): NotificationPermissionStatus {
        val enabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return if (enabled) NotificationPermissionStatus.AUTHORIZED else NotificationPermissionStatus.DENIED
        }
        val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        return when {
            granted && enabled -> NotificationPermissionStatus.AUTHORIZED
            preferences.getBoolean(ASKED_KEY) == true -> NotificationPermissionStatus.DENIED
            else -> NotificationPermissionStatus.NOT_DETERMINED
        }
    }

    override suspend fun requestAuthorization(): Boolean {
        val requester = requester ?: return false
        preferences.putBoolean(ASKED_KEY, true)
        return requester()
    }

    companion object {
        const val ASKED_KEY = "notifications.permissionAsked"
    }
}

/**
 * Plans the reminders with the core planners and hands them to AlarmManager.
 *
 * Runs again, debounced, after every save, on resume, when the preferences change and when the permission is granted.
 */
class NotificationScheduler(private val context: Context, private val container: AppContainer) {
    private var job: Job? = null

    fun scheduleSoon() {
        job?.cancel()
        job = container.scope.launch {
            delay(1000)
            reschedule()
        }
    }

    suspend fun reschedule() {
        if (container.notificationPermission.status() != NotificationPermissionStatus.AUTHORIZED) return
        val store = container.loadStore()
        val preferences = container.preferences
        val reminderTime = ReminderTime.stored(preferences)
        val notificationPreferences = NotificationPreferences.stored(preferences)
        val recurringPlanner = RecurringNotificationPlanner(
            isEnabled = notificationPreferences.remindsRecurringTransactions,
            automaticUnlockedUntil = container.trentePlus.automaticUnlockedUntil,
            reminderTime = reminderTime
        )
        val newMonthPlanner = NewMonthNotificationPlanner(isEnabled = notificationPreferences.announcesNewMonths, reminderTime = reminderTime)
        val inactivityPlanner = InactivityNotificationPlanner(reminderTime = reminderTime)
        val now = Instant.now()
        val lastAppOpen = InactivityNotificationPlanner.storedLastAppOpen(preferences) ?: now

        val latestMonth = MonthService.latestMonth(store)
        val recurring = latestMonth?.let { month ->
            recurringPlanner.requests(store.rules, month.currency, now).map { it.scheduledNotification }
        } ?: emptyList()
        val newMonths = latestMonth?.let { month ->
            newMonthPlanner.requests(month.startDate, now).map { it.scheduledNotification }
        } ?: emptyList()
        val notifications = inactivityPlanner.notifications(
            keeping = NotificationScheduling.soonest(recurring + newMonths, NotificationScheduling.SYSTEM_LIMIT - 1),
            lastAppOpen = lastAppOpen
        )

        withContext(Dispatchers.Default) {
            val alarms = NotificationAlarms(context, preferences)
            alarms.replaceAll(notifications)
        }
        clearSettledRecurringNotifications(recurringPlanner, store.rules)
    }

    private fun clearSettledRecurringNotifications(planner: RecurringNotificationPlanner, rules: List<app.trente.core.model.RecurringTransactionRule>) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val delivered = manager.activeNotifications.mapNotNull { active ->
            val identifier = active.tag ?: return@mapNotNull null
            if (!identifier.startsWith(RecurringNotificationPlanner.IDENTIFIER_PREFIX)) return@mapNotNull null
            val payload = RecurringNotificationPayload.fromUserInfo(NotificationAlarms.userInfo(active.notification.extras)) ?: return@mapNotNull null
            DeliveredNotification(identifier, payload)
        }
        if (delivered.isEmpty()) return
        for (identifier in planner.identifiersToClear(delivered, rules)) {
            manager.cancel(identifier, NotificationAlarms.NOTIFICATION_ID)
        }
    }
}

/** The alarms behind the scheduled notifications, remembered so stale ones can be cancelled. */
class NotificationAlarms(private val context: Context, private val preferences: KeyValueStore) {
    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    fun replaceAll(notifications: List<ScheduledNotification>) {
        val identifiers = notifications.map { it.identifier }.toSet()
        val previous = storedIdentifiers()
        for (stale in previous - identifiers) {
            alarmManager.cancel(pendingIntent(stale, null))
        }
        for (notification in notifications) {
            schedule(notification)
        }
        preferences.putString(SCHEDULED_KEY, identifiers.joinToString("\n"))
    }

    private fun schedule(notification: ScheduledNotification) {
        val intent = pendingIntent(notification.identifier, notification)
        val triggerAt = notification.fireDate.toEpochMilli()
        val canBeExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()
        if (canBeExact) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, intent)
        } else {
            alarmManager.setWindow(AlarmManager.RTC_WAKEUP, triggerAt, 15 * 60 * 1000L, intent)
        }
    }

    private fun storedIdentifiers(): Set<String> =
        preferences.getString(SCHEDULED_KEY)?.split('\n')?.filter { it.isNotEmpty() }?.toSet() ?: emptySet()

    private fun pendingIntent(identifier: String, notification: ScheduledNotification?): PendingIntent {
        val intent = Intent(context, NotificationAlarmReceiver::class.java).apply {
            action = ACTION_SHOW
            data = android.net.Uri.parse("trente-notification://$identifier")
            if (notification != null) {
                putExtra(EXTRA_IDENTIFIER, notification.identifier)
                putExtra(EXTRA_TITLE, notification.title)
                putExtra(EXTRA_BODY, notification.body)
                putExtra(EXTRA_THREAD, notification.threadIdentifier)
                putExtra(EXTRA_CATEGORY, notification.categoryIdentifier)
                putExtra(EXTRA_PASSIVE, notification.prominence == ScheduledNotification.Prominence.PASSIVE)
                notification.userInfo.forEach { (key, value) -> putExtra(EXTRA_USER_INFO_PREFIX + key, value) }
            }
        }
        return PendingIntent.getBroadcast(
            context,
            identifier.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    companion object {
        const val NOTIFICATION_ID = 30
        const val ACTION_SHOW = "app.trente.notifications.SHOW"
        const val EXTRA_IDENTIFIER = "identifier"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_THREAD = "thread"
        const val EXTRA_CATEGORY = "category"
        const val EXTRA_PASSIVE = "passive"
        const val EXTRA_USER_INFO_PREFIX = "userInfo."
        private const val SCHEDULED_KEY = "notifications.scheduledIdentifiers"

        fun userInfo(extras: android.os.Bundle?): Map<String, String> {
            if (extras == null) return emptyMap()
            return extras.keySet()
                .filter { it.startsWith(EXTRA_USER_INFO_PREFIX) }
                .associate { it.removePrefix(EXTRA_USER_INFO_PREFIX) to (extras.getString(it) ?: "") }
        }
    }
}

/** Fires when an alarm goes off: posts the notification. */
class NotificationAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val identifier = intent.getStringExtra(NotificationAlarms.EXTRA_IDENTIFIER) ?: return
        val thread = intent.getStringExtra(NotificationAlarms.EXTRA_THREAD) ?: TrenteNotifications.CHANNEL_RECURRING
        val category = intent.getStringExtra(NotificationAlarms.EXTRA_CATEGORY)
        val isPassive = intent.getBooleanExtra(NotificationAlarms.EXTRA_PASSIVE, false)
        val userInfo = NotificationAlarms.userInfo(intent.extras)

        val openApp = PendingIntent.getActivity(
            context,
            identifier.hashCode(),
            Intent(context, MainActivity::class.java).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val extras = android.os.Bundle().apply {
            userInfo.forEach { (key, value) -> putString(NotificationAlarms.EXTRA_USER_INFO_PREFIX + key, value) }
        }
        val builder = NotificationCompat.Builder(context, TrenteNotifications.channel(thread))
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(intent.getStringExtra(NotificationAlarms.EXTRA_TITLE))
            .setContentText(intent.getStringExtra(NotificationAlarms.EXTRA_BODY))
            .setStyle(NotificationCompat.BigTextStyle().bigText(intent.getStringExtra(NotificationAlarms.EXTRA_BODY)))
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .setGroup(thread)
            .setPriority(if (isPassive) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_DEFAULT)
            .addExtras(extras)
        if (category != null) {
            val markTitle = if (category == RecurringNotificationAction.INCOME_CATEGORY) localized("Mark as Received") else localized("Mark as Paid")
            builder.addAction(0, markTitle, actionIntent(context, identifier, RecurringNotificationAction.MARK_AS_PAID, userInfo))
            builder.addAction(0, localized("Skip"), actionIntent(context, identifier, RecurringNotificationAction.SKIP, userInfo))
        }
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
        ) {
            NotificationManagerCompat.from(context).notify(identifier, NotificationAlarms.NOTIFICATION_ID, builder.build())
        }
    }

    private fun actionIntent(context: Context, identifier: String, action: RecurringNotificationAction, userInfo: Map<String, String>): PendingIntent {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            this.action = action.id
            data = android.net.Uri.parse("trente-notification://$identifier/${action.id}")
            putExtra(NotificationAlarms.EXTRA_IDENTIFIER, identifier)
            userInfo.forEach { (key, value) -> putExtra(NotificationAlarms.EXTRA_USER_INFO_PREFIX + key, value) }
        }
        return PendingIntent.getBroadcast(context, (identifier + action.id).hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}

/** "Mark as Paid" and "Skip" on a due reminder. */
class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = RecurringNotificationAction.fromId(intent.action) ?: return
        val payload = RecurringNotificationPayload.fromUserInfo(NotificationAlarms.userInfo(intent.extras)) ?: return
        val identifier = intent.getStringExtra(NotificationAlarms.EXTRA_IDENTIFIER)
        val container = context.appContainer
        val result = goAsync()
        container.scope.launch {
            try {
                val store = container.loadStore()
                RecurringNotificationResponder.handle(action, payload, store, isTrentePlusSubscribed = container.trentePlus.currentStatus())
                if (identifier != null) {
                    NotificationManagerCompat.from(context).cancel(identifier, NotificationAlarms.NOTIFICATION_ID)
                }
                container.notificationScheduler.scheduleSoon()
            } finally {
                result.finish()
            }
        }
    }
}

/** Alarms don't survive a reboot: plan them again. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED && intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val container = context.appContainer
        val result = goAsync()
        container.scope.launch {
            try {
                container.catchUp()
                container.notificationScheduler.reschedule()
            } finally {
                result.finish()
            }
        }
    }
}

/** Opens the system notification settings of the app. */
fun notificationSettingsIntent(context: Context): Intent =
    Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
