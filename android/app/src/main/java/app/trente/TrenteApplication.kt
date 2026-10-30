package app.trente

import android.app.Application
import android.content.Context
import app.trente.core.support.DateText
import app.trente.core.support.Localization
import app.trente.core.support.MoneyFormat
import app.trente.data.AndroidDateText
import app.trente.data.AndroidMoney
import app.trente.data.AndroidStrings
import app.trente.notifications.TrenteNotifications

class TrenteApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        Localization.provider = AndroidStrings(this)
        DateText.provider = AndroidDateText()
        MoneyFormat.formatter = AndroidMoney()
        TrenteNotifications.createChannels(this)
        container = AppContainer(this)
        container.start()
    }
}

val Context.appContainer: AppContainer
    get() = (applicationContext as TrenteApplication).container
