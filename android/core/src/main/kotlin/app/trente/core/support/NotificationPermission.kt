package app.trente.core.support

enum class NotificationPermissionStatus {
    NOT_DETERMINED,
    AUTHORIZED,
    DENIED
}

/** What the system knows about the notification permission. The app implements it over Android's permission. */
interface NotificationAuthorizing {
    suspend fun currentStatus(): NotificationPermissionStatus

    suspend fun requestAuthorization(): Boolean
}

class NotificationPermissionService(
    private val center: NotificationAuthorizing,
    private val onGranted: () -> Unit = {}
) {
    suspend fun status(): NotificationPermissionStatus = center.currentStatus()

    /** Asks only when the user hasn't answered yet, and returns the answer. */
    suspend fun requestIfNeeded(): NotificationPermissionStatus {
        if (status() != NotificationPermissionStatus.NOT_DETERMINED) return status()
        val isGranted = try {
            center.requestAuthorization()
        } catch (exception: Exception) {
            false
        }
        if (isGranted) onGranted()
        return if (isGranted) NotificationPermissionStatus.AUTHORIZED else NotificationPermissionStatus.DENIED
    }
}
