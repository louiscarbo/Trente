package app.trente.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.StopCircle
import androidx.compose.material.icons.filled.Undo
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.presentation.RecurringTransactionRuleDraft
import app.trente.core.presentation.TransactionGroupDraft
import app.trente.core.services.ImageAttachmentLoader
import app.trente.core.services.RecurringTransactionService
import app.trente.core.services.TransactionService
import app.trente.core.support.localized
import app.trente.data.AndroidImagePreparer
import app.trente.ui.LocalShowPaywall
import app.trente.ui.components.AttachmentThumbnail
import app.trente.ui.components.CloseStyle
import app.trente.ui.components.CurrencyTextField
import app.trente.ui.components.DateField
import app.trente.ui.components.DeleteConfirmationDialog
import app.trente.ui.components.DeleteSectionBox
import app.trente.ui.components.EditableExpenseRow
import app.trente.ui.components.EditableTitleField
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.IncomeRepartitionComponent
import app.trente.ui.components.LabeledPicker
import app.trente.ui.components.NotesField
import app.trente.ui.components.RequiresTrentePlus
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.components.TrenteToggle
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.components.rememberImageBitmap
import app.trente.ui.dataVersion
import app.trente.ui.isTrentePlusSubscribed
import app.trente.ui.rememberStore
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import java.time.Instant
import java.util.UUID
import kotlinx.coroutines.launch

/** A view/edit screen with Edit, Close, Cancel and Done, validation and deletion, like `DetailEditScaffold`. */
@Composable
fun DetailEditScaffold(
    title: String,
    isEditing: Boolean,
    onBeginEdit: () -> Unit,
    onCancel: () -> Unit,
    onDone: () -> Unit,
    onClose: () -> Unit,
    isDoneDisabled: Boolean = false,
    deleteSectionTitle: String? = null,
    onDelete: (() -> Unit)? = null,
    validationErrors: List<String>,
    onClearValidationErrors: () -> Unit,
    deleteError: String?,
    onClearDeleteError: () -> Unit,
    content: @Composable () -> Unit
) {
    Scaffold(
        topBar = {
            TrenteTopBar(
                title = if (isEditing) localized("Editing") else title,
                onBack = if (isEditing) null else onClose,
                closeStyle = CloseStyle.CLOSE
            ) {
                if (isEditing) {
                    IconButton(onClick = onCancel) { Icon(Icons.Default.Undo, contentDescription = localized("Cancel")) }
                    TextButton(onClick = onDone, enabled = !isDoneDisabled) { Text(localized("Done")) }
                } else {
                    IconButton(onClick = onBeginEdit) { Icon(Icons.Default.Edit, contentDescription = localized("Edit")) }
                }
            }
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).imePadding().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            content()
            if (isEditing && deleteSectionTitle != null && onDelete != null) {
                DeleteSectionBox(title = deleteSectionTitle, onDelete = onDelete)
            }
        }
    }
    if (validationErrors.isNotEmpty()) {
        AlertDialog(
            onDismissRequest = onClearValidationErrors,
            title = { Text(localized("Cannot Save")) },
            text = { Text(validationErrors.joinToString("\n")) },
            confirmButton = { TextButton(onClick = onClearValidationErrors) { Text(localized("OK")) } }
        )
    }
    ErrorAlert(message = deleteError, onDismiss = onClearDeleteError, title = localized("Delete Failed"))
}

/** View or edit a transaction, like `TransactionGroupDetailsView`. */
@Composable
fun TransactionGroupDetailsScreen(groupId: UUID, startInEditMode: Boolean, onClose: () -> Unit) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val group = remember(version, groupId) { store.transactionGroup(groupId) }
    if (group == null) {
        LaunchedEffect(Unit) { onClose() }
        return
    }
    var isEditing by remember { mutableStateOf(startInEditMode) }
    var draft by remember(group, isEditing) { mutableStateOf(TransactionGroupDraft.from(group)) }
    var isRepartitionComplete by remember { mutableStateOf(true) }
    var validationErrors by remember { mutableStateOf(emptyList<String>()) }
    var deleteError by remember { mutableStateOf<String?>(null) }
    var saveError by remember { mutableStateOf<String?>(null) }
    val currencyCode = group.currency.isoCode
    fun edit(block: TransactionGroupDraft.() -> Unit) {
        draft = draft.copy().apply(block)
    }

    DetailEditScaffold(
        title = group.title,
        isEditing = isEditing,
        onBeginEdit = { isEditing = true },
        onCancel = { isEditing = false },
        onDone = {
            draft.fillMissingAmountToSplit()
            val issues = draft.validate()
            if (issues.isNotEmpty()) {
                validationErrors = issues
            } else {
                try {
                    draft.apply(group, store)
                    store.save()
                    isEditing = false
                } catch (exception: Exception) {
                    saveError = localized("Failed to save changes: %@", exception.localizedMessage ?: exception.toString())
                }
            }
        },
        onClose = onClose,
        isDoneDisabled = group.type == TransactionType.INCOME && !isRepartitionComplete,
        deleteSectionTitle = localized("Delete Transaction"),
        onDelete = {
            try {
                TransactionService.delete(group, store)
                store.save()
                onClose()
            } catch (exception: Exception) {
                deleteError = exception.localizedMessage ?: exception.toString()
            }
        },
        validationErrors = validationErrors,
        onClearValidationErrors = { validationErrors = emptyList() },
        deleteError = deleteError,
        onClearDeleteError = { deleteError = null }
    ) {
        EditableTransactionHeader(
            draft = draft,
            isEditing = isEditing,
            showsExpenseRow = group.type == TransactionType.EXPENSE,
            currencyCode = currencyCode,
            onEdit = ::edit
        )
        if (group.type == TransactionType.INCOME) {
            TrenteCard(label = localized("Income Repartition"), icon = Icons.Default.PieChart) {
                IncomeRepartitionComponent(
                    repartition = draft.incomeRepartition,
                    amountToSplit = draft.incomeAmountToSplitCents,
                    currencyCode = currencyCode,
                    enabled = isEditing,
                    onRepartitionChange = { repartition -> edit { incomeRepartition = repartition } },
                    onCompleteChange = { isRepartitionComplete = it }
                )
            }
        }
    }
    ErrorAlert(message = saveError, onDismiss = { saveError = null })
}

/** The card with the photo, the title, the category and amount, and the notes, like `EditableTransactionHeader`. */
@Composable
fun EditableTransactionHeader(
    draft: TransactionGroupDraft,
    isEditing: Boolean,
    showsExpenseRow: Boolean,
    currencyCode: String,
    onEdit: (TransactionGroupDraft.() -> Unit) -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val isSubscribed = isTrentePlusSubscribed()
    val showPaywall = LocalShowPaywall.current
    val loader = remember { ImageAttachmentLoader(scope, AndroidImagePreparer) }
    var loaderTick by remember { mutableIntStateOf(0) }
    var isConfirmingImageDelete by remember { mutableStateOf(false) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            loader.load({ AndroidImagePreparer.read(context, uri) }) { data -> onEdit { imageAttachmentData = data } }
            loaderTick += 1
            scope.launch { loader.currentLoad?.join(); loaderTick += 1 }
        }
    }
    @Suppress("UNUSED_EXPRESSION") loaderTick
    val image = rememberImageBitmap(draft.imageAttachmentData)

    TrenteCard(withPadding = false) {
        Box(Modifier.fillMaxWidth()) {
            when {
                loader.isLoading -> Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                image != null -> AttachmentThumbnail(
                    image = image,
                    modifier = Modifier.fillMaxWidth().height(200.dp).clip(RoundedCornerShape(topStart = 26.dp, topEnd = 26.dp))
                )
                isEditing -> Box(Modifier.padding(16.dp)) {
                    RequiresTrentePlus(isSubscribed = isSubscribed, onShowPaywall = showPaywall) {
                        TrenteSecondaryButton(text = localized("Add Image"), icon = Icons.Default.AddPhotoAlternate, narrow = true, onClick = {
                            picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                        })
                    }
                }
            }
            if (isEditing && image != null) {
                FilledIconButton(
                    onClick = { isConfirmingImageDelete = true },
                    colors = IconButtonDefaults.filledIconButtonColors(containerColor = MaterialTheme.colorScheme.error),
                    modifier = Modifier.align(Alignment.BottomEnd).padding(12.dp)
                ) { Icon(Icons.Default.Delete, contentDescription = localized("Delete Image")) }
            }
        }
        Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 16.dp, top = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            EditableTitleField(text = draft.title, onTextChange = { text -> onEdit { title = text } }, isEditing = isEditing, placeholder = localized("Transaction title"))
            if (showsExpenseRow) {
                EditableExpenseRow(
                    category = draft.expenseCategory,
                    onCategoryChange = { category -> onEdit { expenseCategory = category } },
                    amountCents = draft.expenseAmountCents,
                    onAmountChange = { cents -> onEdit { expenseAmountCents = cents } },
                    isEditing = isEditing,
                    currencyCode = currencyCode
                )
            }
            if (isEditing) {
                RequiresTrentePlus(isSubscribed = isSubscribed, onShowPaywall = showPaywall) {
                    NotesField(text = draft.note, onTextChange = { text -> onEdit { note = text } }, isEditing = true)
                }
            } else if (draft.note.isNotEmpty()) {
                NotesField(text = draft.note, onTextChange = {}, isEditing = false)
            }
        }
    }
    if (isConfirmingImageDelete) {
        DeleteConfirmationDialog(onDismiss = { isConfirmingImageDelete = false }, onDelete = { isConfirmingImageDelete = false; onEdit { imageAttachmentData = null } })
    }
    ErrorAlert(message = loader.error, onDismiss = { loader.error = null; loaderTick += 1 }, title = localized("Error Loading Image"))
}

/** View or edit a recurring rule, stop or delete it, like `RecurringTransactionRuleDetailsView`. */
@Composable
fun RecurringRuleDetailsScreen(ruleId: UUID, onClose: () -> Unit) {
    val store = rememberStore() ?: return
    val version = dataVersion()
    val rule = remember(version, ruleId) { store.rule(ruleId) }
    if (rule == null) {
        LaunchedEffect(Unit) { onClose() }
        return
    }
    val currencyCode = remember(version) { store.months.maxByOrNull { it.startDate }?.currency?.isoCode ?: app.trente.core.model.Currency.fallback.isoCode }
    val isSubscribed = isTrentePlusSubscribed()
    val showPaywall = LocalShowPaywall.current
    val calendar = TrenteCalendar.current
    var isEditing by remember { mutableStateOf(false) }
    val draft = remember(rule, isEditing, version) { RecurringTransactionRuleDraft.from(rule) }
    var tick by remember { mutableIntStateOf(0) }
    @Suppress("UNUSED_EXPRESSION") tick
    fun edit(block: RecurringTransactionRuleDraft.() -> Unit) {
        draft.block()
        tick += 1
    }
    var isRepartitionComplete by remember { mutableStateOf(true) }
    var validationErrors by remember { mutableStateOf(emptyList<String>()) }
    var deleteError by remember { mutableStateOf<String?>(null) }
    var saveError by remember { mutableStateOf<String?>(null) }
    var stopError by remember { mutableStateOf<String?>(null) }
    var isConfirmingStop by remember { mutableStateOf(false) }
    val isIncome = rule.amountCents > 0
    val today = calendar.startOfDay(Instant.now())

    DetailEditScaffold(
        title = rule.title,
        isEditing = isEditing,
        onBeginEdit = { isEditing = true },
        onCancel = { isEditing = false },
        onDone = {
            val issues = draft.validate()
            if (issues.isNotEmpty()) {
                validationErrors = issues
            } else {
                try {
                    draft.apply(rule)
                    store.save()
                    isEditing = false
                } catch (exception: Exception) {
                    saveError = localized("Failed to save changes: %@", exception.localizedMessage ?: exception.toString())
                }
            }
        },
        onClose = onClose,
        isDoneDisabled = isIncome && draft.repartitionTotalCents != 0 && !isRepartitionComplete,
        deleteSectionTitle = localized("Delete Recurring Transaction"),
        onDelete = {
            try {
                RecurringTransactionService.delete(rule, store)
                store.save()
                onClose()
            } catch (exception: Exception) {
                deleteError = exception.localizedMessage ?: exception.toString()
            }
        },
        validationErrors = validationErrors,
        onClearValidationErrors = { validationErrors = emptyList() },
        deleteError = deleteError,
        onClearDeleteError = { deleteError = null }
    ) {
        TrenteCard {
            EditableTitleField(text = draft.title, onTextChange = { text -> edit { title = text } }, isEditing = isEditing, placeholder = localized("Recurring transaction title"))
            Surface(shape = CircleShape, color = TrenteColors.gray.copy(alpha = 0.15f), border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.15f))) {
                Text(rule.frequencyDescription(), style = TrenteType.subheadline, color = TrenteColors.secondaryText, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp))
            }
            if (!isIncome) {
                EditableExpenseRow(
                    category = draft.expenseCategory,
                    onCategoryChange = { category -> edit { expenseCategory = category } },
                    amountCents = draft.expenseAmountCents,
                    onAmountChange = { cents -> edit { expenseAmountCents = cents } },
                    isEditing = isEditing,
                    currencyCode = currencyCode
                )
            }
        }
        TrenteCard(label = localized("Recurrence Details"), icon = Icons.Default.CalendarMonth) {
            LabeledPicker(
                title = localized("Frequency"),
                selection = draft.frequency,
                options = RecurrenceFrequency.entries,
                onSelect = { frequency -> edit { setFrequency(frequency) } },
                enabled = isEditing,
                optionTitle = { it.displayName }
            )
            DateField(label = localized("Start Date"), date = draft.startDate, onDateChange = { date -> edit { startDate = date } }, enabled = isEditing, minDate = if (isEditing) today else null)
            val endDate = draft.endDate
            when {
                endDate != null -> Row(verticalAlignment = Alignment.CenterVertically) {
                    DateField(
                        label = localized("End Date"),
                        date = endDate,
                        onDateChange = { date -> edit { this.endDate = date } },
                        enabled = isEditing,
                        minDate = calendar.plusDays(draft.startDate, 7),
                        modifier = Modifier.weight(1f)
                    )
                    if (isEditing) {
                        IconButton(onClick = { edit { this.endDate = null } }) { Icon(Icons.Default.Cancel, contentDescription = localized("Remove End Date")) }
                    }
                }
                isEditing -> TrentePrimaryButton(text = localized("Add an End Date"), narrow = true, onClick = { edit { this.endDate = calendar.plusDays(startDate, 7) } })
            }
        }
        TrenteCard(label = localized("Automatic"), icon = Icons.Default.CheckCircle) {
            RequiresTrentePlus(isSubscribed = isSubscribed, onShowPaywall = showPaywall, isRequired = isEditing && !draft.autoConfirm) {
                TrenteToggle(checked = draft.autoConfirm, onCheckedChange = { checked -> edit { autoConfirm = checked } }, enabled = isEditing) {
                    Text(if (isIncome) localized("Mark as received automatically") else localized("Mark as paid automatically"), style = TrenteType.body)
                }
            }
            Text(
                if (draft.autoConfirm && !isSubscribed) {
                    localized("Paused without Trente+. Until you subscribe again, you'll be asked to confirm %@.", rule.title)
                } else {
                    localized("On the due date, %@ is added to that month's transactions.", rule.title)
                },
                style = TrenteType.subheadline,
                color = TrenteColors.secondaryText
            )
        }
        if (isIncome) {
            TrenteCard(label = localized("Repartition"), icon = Icons.Default.PieChart) {
                if (isEditing) {
                    CurrencyTextField(
                        amountCents = draft.repartitionTotalCents,
                        onAmountChange = { cents -> edit { repartitionTotalCents = cents } },
                        currencyCode = currencyCode,
                        textStyle = TrenteType.title,
                        modifier = Modifier.fillMaxWidth().background(TrenteColors.gray.copy(alpha = 0.2f), RoundedCornerShape(10.dp)).padding(8.dp)
                    )
                }
                IncomeRepartitionComponent(
                    repartition = draft.repartition,
                    amountToSplit = draft.repartitionTotalCents,
                    currencyCode = currencyCode,
                    enabled = isEditing,
                    onRepartitionChange = { repartition -> edit { this.repartition = repartition } },
                    onCompleteChange = { isRepartitionComplete = it }
                )
            }
        }
        if (!isEditing && !rule.hasEnded()) {
            TrenteCard(label = localized("Stop Future Transactions"), icon = Icons.Default.StopCircle) {
                Text(localized("%@ won't appear after today. Transactions already recorded stay.", rule.title), style = TrenteType.subheadline, color = TrenteColors.secondaryText)
                TrentePrimaryButton(text = localized("Stop Future Transactions"), icon = Icons.Default.StopCircle, narrow = true, onClick = { isConfirmingStop = true })
            }
        }
    }
    if (isConfirmingStop) {
        AlertDialog(
            onDismissRequest = { isConfirmingStop = false },
            title = { Text(localized("Stop future %@ transactions?", rule.title)) },
            text = { Text(localized("%@ won't appear after today. Transactions already recorded stay.", rule.title)) },
            confirmButton = {
                TextButton(onClick = {
                    isConfirmingStop = false
                    try {
                        RecurringTransactionService.stop(rule, store)
                    } catch (exception: Exception) {
                        stopError = exception.localizedMessage ?: exception.toString()
                    }
                }) { Text(localized("Stop Future Transactions"), color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { isConfirmingStop = false }) { Text(localized("Cancel")) } }
        )
    }
    ErrorAlert(message = saveError, onDismiss = { saveError = null })
    ErrorAlert(message = stopError, onDismiss = { stopError = null }, title = localized("Stop Failed"))
}
