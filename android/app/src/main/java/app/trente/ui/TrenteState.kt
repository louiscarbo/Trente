package app.trente.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.staticCompositionLocalOf
import app.trente.AppContainer
import app.trente.core.model.RecurringTransactionOccurrence
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TrenteStore
import app.trente.core.services.RecurringTransactionService
import app.trente.core.services.TransactionService

val LocalAppContainer = staticCompositionLocalOf<AppContainer> { error("No AppContainer provided") }

/** Opens the Trente+ paywall from anywhere. */
val LocalShowPaywall = compositionLocalOf<() -> Unit> { {} }

/** The loaded store, or null while it loads. */
@Composable
fun rememberStore(): TrenteStore? {
    val container = LocalAppContainer.current
    val store by container.store.collectAsState()
    LaunchedEffect(Unit) { container.loadStore() }
    return store
}

/** Changes after every save; read it so the screen recomposes with the new graph. */
@Composable
fun dataVersion(): Long {
    val version: State<Long> = LocalAppContainer.current.dataVersion.collectAsState()
    return version.value
}

@Composable
fun isTrentePlusSubscribed(): Boolean {
    val subscribed by LocalAppContainer.current.trentePlus.isSubscribed.collectAsState()
    return subscribed
}

/** The row actions, reporting failures to an alert, like the iOS `TransactionActions`. */
class TransactionActions(private val store: TrenteStore, private val reportError: (String) -> Unit) {
    fun delete(group: TransactionGroup) = perform {
        TransactionService.delete(group, store)
        store.save()
    }

    fun delete(rule: RecurringTransactionRule) = perform {
        RecurringTransactionService.delete(rule, store)
        store.save()
    }

    fun confirm(occurrence: RecurringTransactionOccurrence) = perform { RecurringTransactionService.confirm(occurrence, store) }

    fun skip(occurrence: RecurringTransactionOccurrence) = perform { RecurringTransactionService.skip(occurrence, store) }

    private fun perform(action: () -> Unit) {
        try {
            action()
        } catch (exception: Exception) {
            reportError(exception.localizedMessage ?: exception.toString())
        }
    }
}
