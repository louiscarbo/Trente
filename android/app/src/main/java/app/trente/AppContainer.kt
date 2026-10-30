package app.trente

import android.app.Application
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import app.trente.billing.TrentePlusStatus
import app.trente.core.model.TrenteStore
import app.trente.core.services.CatchUpService
import app.trente.core.services.SampleData
import app.trente.core.services.notifications.InactivityNotificationPlanner
import app.trente.core.support.NotificationPermissionService
import app.trente.data.PreferencesStore
import app.trente.data.RoomBackend
import app.trente.data.TrenteDatabase
import app.trente.notifications.AndroidNotificationCenter
import app.trente.notifications.NotificationScheduler
import app.trente.widgets.WidgetRefresher
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Everything the app shares: the store, preferences, the subscription, notifications and the widgets.
 *
 * The store lives on the main thread, like SwiftData's main context. Every screen reads the same graph and
 * observes [dataVersion] to know when to read it again.
 */
class AppContainer(private val application: Application) {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    val preferences = PreferencesStore(application)
    val usesSampleData: Boolean = BuildConfig.USES_SAMPLE_DATA
    private val database: TrenteDatabase = if (usesSampleData) TrenteDatabase.inMemory(application) else TrenteDatabase.open(application)
    private val imagesDirectory = File(application.filesDir, "images")
    private val backend = RoomBackend(database.dao(), imagesDirectory, onWritten = { widgetRefresher.refresh() })

    private val mutableStore = MutableStateFlow<TrenteStore?>(null)

    /** The store once loaded; screens wait for it. */
    val store: StateFlow<TrenteStore?> get() = mutableStore

    private val mutableDataVersion = MutableStateFlow(0L)

    /** Bumped after every save. */
    val dataVersion: StateFlow<Long> get() = mutableDataVersion

    val trentePlus = TrentePlusStatus(application, preferences, scope)
    val notificationCenter = AndroidNotificationCenter(application, preferences)
    val notificationPermission = NotificationPermissionService(notificationCenter) { notificationScheduler.scheduleSoon() }
    val notificationScheduler = NotificationScheduler(application, this)
    val widgetRefresher = WidgetRefresher(application, scope)

    private val loadMutex = Mutex()
    private var catchUpJob: Job? = null

    fun start() {
        trentePlus.start()
        ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                InactivityNotificationPlanner.recordAppOpen(defaults = preferences)
                scope.launch {
                    loadStore()
                    catchUp()
                }
            }
        })
        scope.launch {
            trentePlus.isSubscribed.collect {
                catchUp()
                widgetRefresher.refresh()
            }
        }
    }

    /** Loads the graph from the database once; later calls return the same store. */
    suspend fun loadStore(): TrenteStore {
        mutableStore.value?.let { return it }
        return loadMutex.withLock {
            mutableStore.value?.let { return it }
            val loaded = withContext(Dispatchers.IO) { TrenteStore.load(backend) }
            if (usesSampleData && loaded.months.isEmpty()) {
                SampleData.populate(loaded)
            }
            loaded.addListener { onStoreSaved() }
            mutableStore.value = loaded
            loaded
        }
    }

    private fun onStoreSaved() {
        mutableDataVersion.value += 1
        notificationScheduler.scheduleSoon()
        scheduleCatchUp()
    }

    /** Starts the missing months and records the automatic transactions that are due. */
    suspend fun catchUp() {
        val store = loadStore()
        val isSubscribed = trentePlus.currentStatus()
        CatchUpService.catchUp(store, isTrentePlusSubscribed = isSubscribed)
    }

    private fun scheduleCatchUp() {
        catchUpJob?.cancel()
        catchUpJob = scope.launch {
            delay(200)
            catchUp()
        }
    }
}
