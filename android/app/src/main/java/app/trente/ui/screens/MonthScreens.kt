package app.trente.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Undo
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.trente.core.model.Currencies
import app.trente.core.model.Month
import app.trente.core.presentation.MonthDraft
import app.trente.core.services.MonthService
import app.trente.core.services.export.TransactionCSVFormat
import app.trente.core.services.export.TransactionsCSVFile
import app.trente.core.support.localized
import app.trente.ui.LocalAppContainer
import app.trente.ui.components.CloseStyle
import app.trente.ui.components.DeleteSectionBox
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.ExportButton
import app.trente.ui.components.MonthDetailsComponent
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.dataVersion
import app.trente.ui.rememberStore
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import java.time.Instant
import java.util.UUID

/** Starts a month after the latest one, with the same budget, like `NewMonthView`. */
@Composable
fun NewMonthScreen(onClose: () -> Unit, onCreated: (UUID) -> Unit) {
    val store = rememberStore() ?: return
    var draft by remember {
        val latest = MonthService.latestMonth(store)
        mutableStateOf(
            if (latest != null) {
                MonthDraft(startDate = latest.dateInterval.end, currency = latest.currency, idealBudgetCents = latest.idealBudgetCents, idealRepartition = latest.idealRepartition)
            } else {
                MonthDraft(startDate = Instant.now(), currency = Currencies.currency("EUR")!!, idealBudgetCents = 0, idealRepartition = emptyMap())
            }
        )
    }
    var isRepartitionComplete by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val canCreate = draft.idealBudgetCents > 0 && isRepartitionComplete

    fun create() {
        try {
            val month = draft.makeMonth()
            MonthService.create(month, store)
            onCreated(month.id)
        } catch (exception: Exception) {
            error = exception.localizedMessage?.ifEmpty { null } ?: localized("We couldn't create the month. Please try again.")
        }
    }

    Scaffold(
        topBar = {
            TrenteTopBar(title = localized("New Month"), onBack = onClose, closeStyle = CloseStyle.CANCEL) {
                TextButton(onClick = ::create, enabled = canCreate) { Text(localized("Create")) }
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).imePadding().padding(16.dp)) {
            MonthDetailsComponent(draft = draft, onDraftChange = { draft = it }, onRepartitionCompleteChange = { isRepartitionComplete = it })
        }
    }
    ErrorAlert(message = error, onDismiss = { error = null }, retry = ::create)
}

/** Edits a month's start date, currency and budget; exports or deletes it, like `MonthDetailsView`. */
@Composable
fun MonthDetailsScreen(monthId: UUID, onBack: () -> Unit, onDeleted: () -> Unit) {
    val store = rememberStore() ?: return
    val container = LocalAppContainer.current
    val version = dataVersion()
    val month: Month? = remember(version, monthId) { store.month(monthId) }
    if (month == null) {
        LaunchedEffect(Unit) { onBack() }
        return
    }
    val original = remember(month) { MonthDraft.from(month) }
    var draft by remember(month) { mutableStateOf(original) }
    var isRepartitionComplete by remember { mutableStateOf(true) }
    var error by remember { mutableStateOf<String?>(null) }
    val hasChanges = draft != original
    val canSave = draft.idealBudgetCents > 0 && isRepartitionComplete

    fun save() {
        try {
            draft.apply(month)
            store.save()
        } catch (exception: Exception) {
            error = exception.localizedMessage ?: exception.toString()
        }
    }

    val includesNotes = container.preferences.getBoolean(TransactionCSVFormat.INCLUDES_NOTES_KEY) ?: true
    val includesImages = container.preferences.getBoolean(TransactionCSVFormat.INCLUDES_IMAGES_KEY) ?: true
    val hasImages = remember(version) { month.transactionGroups.any { it.hasImageAttachment } }
    val exportFile = TransactionsCSVFile(
        monthIDs = listOf(month.id),
        fileName = TransactionsCSVFile.fileName(month),
        format = TransactionCSVFormat(style = TransactionCSVFormat.Style.current, includesNotes = includesNotes, includesImages = includesImages),
        hasImages = hasImages
    )

    Scaffold(
        topBar = {
            TrenteTopBar(title = Month.name(draft.startDate), onBack = if (hasChanges) null else onBack) {
                if (hasChanges) {
                    IconButton(onClick = { draft = original }) { Icon(Icons.Default.Undo, contentDescription = localized("Cancel")) }
                    TextButton(onClick = ::save, enabled = canSave) { Text(localized("Save")) }
                }
            }
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).imePadding().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            MonthDetailsComponent(draft = draft, onDraftChange = { draft = it }, onRepartitionCompleteChange = { isRepartitionComplete = it })
            TrenteCard(label = localized("Export Month"), icon = Icons.Default.Share) {
                val hasTransactions = month.transactionGroups.isNotEmpty()
                Text(
                    when {
                        !hasTransactions -> localized("This month has no transactions to export yet.")
                        exportFile.includesImages -> localized("Save this month's transactions and their images in a .zip file, with a spreadsheet (.csv) that opens in Numbers, Excel or Google Sheets.")
                        else -> localized("Save this month's transactions as a spreadsheet file (.csv) that opens in Numbers, Excel or Google Sheets.")
                    },
                    style = TrenteType.subheadline,
                    color = TrenteColors.secondaryText
                )
                ExportButton(title = localized("Export…"), file = exportFile, store = store, enabled = hasTransactions)
                Text(localized("To export several months or choose what to include, go to Settings › Export Transactions."), style = TrenteType.footnote, color = TrenteColors.secondaryText)
            }
            DeleteSectionBox(
                title = localized("Delete Month"),
                message = localized("This action cannot be undone. All transactions associated with this month will also be deleted."),
                onDelete = {
                    try {
                        MonthService.delete(month, store)
                        store.save()
                        onDeleted()
                    } catch (exception: Exception) {
                        error = exception.localizedMessage ?: exception.toString()
                    }
                }
            )
        }
    }
    ErrorAlert(message = error, onDismiss = { error = null }, retry = ::save)
}
