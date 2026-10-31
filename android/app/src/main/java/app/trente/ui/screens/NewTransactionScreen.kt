package app.trente.ui.screens

import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.presentation.NewTransactionStep
import app.trente.core.presentation.NewTransactionViewModel
import app.trente.core.support.localized
import app.trente.data.AndroidImagePreparer
import app.trente.ui.LocalAppContainer
import app.trente.ui.LocalShowPaywall
import app.trente.ui.Observed
import app.trente.ui.components.AttachmentThumbnail
import app.trente.ui.components.BottomBarBackground
import app.trente.ui.components.CloseStyle
import app.trente.ui.components.CurrencyTextField
import app.trente.ui.components.DateField
import app.trente.ui.components.ErrorAlert
import app.trente.ui.components.IncomeRepartitionComponent
import app.trente.ui.components.LabeledPicker
import app.trente.ui.components.NotesField
import app.trente.ui.components.RequiresTrentePlusSection
import app.trente.ui.components.TrenteCard
import app.trente.ui.components.TrentePrimaryButton
import app.trente.ui.components.TrenteSecondaryButton
import app.trente.ui.components.TrenteToggle
import app.trente.ui.components.TrenteTopBar
import app.trente.ui.components.rememberImageBitmap
import app.trente.ui.isTrentePlusSubscribed
import app.trente.ui.rememberStore
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import java.time.Instant
import java.util.UUID
import kotlinx.coroutines.launch

/** The add-transaction wizard: amount and category, title, split, notes and image, recurrence; like `NewTransactionView`. */
@Composable
fun NewTransactionScreen(monthId: UUID, onClose: () -> Unit) {
    val store = rememberStore() ?: return
    val container = LocalAppContainer.current
    val month = remember(monthId) { store.month(monthId) }
    if (month == null) {
        LaunchedEffect(Unit) { onClose() }
        return
    }
    val model = remember { Observed(NewTransactionViewModel(container.scope, container.notificationPermission, AndroidImagePreparer)) }
    val currencyCode = month.currency.isoCode
    var showsError by remember { mutableStateOf(false) }

    fun create() {
        if (model.value.createTransaction(month, store)) onClose() else showsError = true
    }

    BackHandler(enabled = model.value.showPreviousButton) { model.mutate { previousStep() } }

    Scaffold(
        topBar = {
            TrenteTopBar(
                title = localized("New Transaction"),
                onBack = if (model.value.step == NewTransactionStep.AMOUNT_CATEGORY) onClose else null,
                closeStyle = CloseStyle.CLOSE
            )
        },
        bottomBar = {
            BottomBarBackground(Modifier.imePadding()) {
                Row(
                    Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    if (model.value.showPreviousButton) {
                        TrenteSecondaryButton(text = localized("Previous"), narrow = true, onClick = { model.mutate { previousStep() } }, modifier = Modifier.weight(1f))
                    }
                    TrentePrimaryButton(
                        text = if (model.value.isLastStep) localized("Create") else localized("Next"),
                        narrow = true,
                        enabled = model.value.canAdvance,
                        onClick = { if (model.value.isLastStep) create() else model.mutate { nextStep() } },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when (model.value.step) {
                NewTransactionStep.AMOUNT_CATEGORY -> AmountCategoryStep(model, currencyCode)
                NewTransactionStep.TITLE -> TitleStep(model)
                NewTransactionStep.REPARTITION -> RepartitionStep(model, currencyCode)
                NewTransactionStep.NOTES_IMAGE -> NotesImageStep(model)
                NewTransactionStep.RECURRENCE -> RecurrenceStep(model)
            }
        }
    }
    if (showsError) {
        ErrorAlert(
            message = localized("We couldn't create the transaction. Please try again."),
            onDismiss = { showsError = false; onClose() },
            retry = { showsError = false; create() }
        )
    }
    ErrorAlert(message = model.value.imageLoadingError, onDismiss = { model.mutate { imageLoadingError = null } }, title = localized("Error Loading Image"))
}

@Composable
private fun RepartitionStep(model: Observed<NewTransactionViewModel>, currencyCode: String) {
    val request = model.value.request
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
        TrenteCard(label = localized("Income Repartition"), icon = Icons.Default.PieChart) {
            Text(localized("How would you like to split this income?"), style = TrenteType.body)
            IncomeRepartitionComponent(
                repartition = request.repartition,
                amountToSplit = request.amountCents,
                currencyCode = currencyCode,
                onRepartitionChange = { model.mutate { request.repartition = it } },
                onCompleteChange = { model.mutate { isRepartitionComplete = it } }
            )
        }
    }
}

@Composable
private fun AmountCategoryStep(model: Observed<NewTransactionViewModel>, currencyCode: String) {
    val request = model.value.request
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(600)
        try { focusRequester.requestFocus() } catch (exception: Exception) { }
    }
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Icon(Icons.Default.Info, contentDescription = null, tint = TrenteColors.secondaryText)
            Spacer(Modifier.width(8.dp))
            Text(
                when {
                    request.type == TransactionType.INCOME -> localized("You will select categories for this income in the next steps.")
                    request.selectedCategory != null -> request.selectedCategory!!.shortExamples
                    else -> localized("Select a category for this transaction.")
                },
                style = TrenteType.headline,
                color = TrenteColors.secondaryText
            )
        }
        if (request.type == TransactionType.EXPENSE) {
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                BudgetCategory.entries.forEachIndexed { index, category ->
                    SegmentedButton(
                        selected = request.selectedCategory == category,
                        onClick = { model.mutate { request.selectedCategory = category } },
                        shape = SegmentedButtonDefaults.itemShape(index, BudgetCategory.entries.size)
                    ) { Text(category.shortName) }
                }
            }
        }
        Spacer(Modifier.weight(1f))
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            listOf(TransactionType.EXPENSE to localized("Expense"), TransactionType.INCOME to localized("Income")).forEachIndexed { index, (type, title) ->
                SegmentedButton(selected = request.type == type, onClick = { model.mutate { request.type = type } }, shape = SegmentedButtonDefaults.itemShape(index, 2)) {
                    Text(title)
                }
            }
        }
        CurrencyTextField(
            amountCents = request.amountCents,
            onAmountChange = { model.mutate { request.amountCents = it } },
            currencyCode = currencyCode,
            textStyle = TrenteType.largeTitle.copy(fontSize = 56.sp, lineHeight = 64.sp),
            textAlign = TextAlign.Center,
            focusRequester = focusRequester,
            modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp)
        )
        Spacer(Modifier.weight(1f))
        TrenteToggle(checked = request.isRecurrent, onCheckedChange = { model.mutate { request.isRecurrent = it } }) {
            Text(localized("Recurring transaction"), style = TrenteType.headline)
        }
    }
}

@Composable
private fun TitleStep(model: Observed<NewTransactionViewModel>) {
    val request = model.value.request
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { try { focusRequester.requestFocus() } catch (exception: Exception) { } }
    val color = LocalContentColor.current
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Row(verticalAlignment = Alignment.Top) {
            Icon(Icons.Default.Info, contentDescription = null, tint = TrenteColors.secondaryText)
            Spacer(Modifier.width(8.dp))
            Text(localized("Give a title to your transaction"), style = TrenteType.headline, color = TrenteColors.secondaryText)
        }
        Spacer(Modifier.weight(1f))
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            if (request.title.isEmpty()) {
                Text(localized("Title"), style = TrenteType.largeTitle.copy(fontSize = 40.sp, lineHeight = 48.sp), color = TrenteColors.secondaryText.copy(alpha = 0.5f))
            }
            BasicTextField(
                value = request.title,
                onValueChange = { model.mutate { request.title = it } },
                textStyle = TrenteType.largeTitle.copy(fontSize = 40.sp, lineHeight = 48.sp, color = color, textAlign = TextAlign.Center),
                cursorBrush = SolidColor(color),
                maxLines = 3,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, imeAction = ImeAction.Done),
                modifier = Modifier.fillMaxWidth().focusRequester(focusRequester)
            )
        }
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun NotesImageStep(model: Observed<NewTransactionViewModel>) {
    val request = model.value.request
    val isLoadingImage = model.value.isLoadingImage
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val isSubscribed = isTrentePlusSubscribed()
    val showPaywall = LocalShowPaywall.current
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) {
            model.mutate { loadImage { AndroidImagePreparer.read(context, uri) } }
            scope.launch {
                model.value.imageLoader.currentLoad?.join()
                model.refresh()
            }
        }
    }
    val image = rememberImageBitmap(request.imageData)
    RequiresTrentePlusSection(isSubscribed = isSubscribed, prompt = localized("Add notes and images with Trente+"), onShowPaywall = showPaywall, modifier = Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp).padding(top = 14.dp), verticalArrangement = Arrangement.spacedBy(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            when {
                isLoadingImage -> Box(Modifier.height(200.dp), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                image != null -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    AttachmentThumbnail(image = image, contentScale = ContentScale.Fit, modifier = Modifier.height(200.dp).clip(CardShape))
                    TrenteSecondaryButton(text = localized("Change Image"), icon = Icons.Default.AddPhotoAlternate, narrow = true, onClick = {
                        picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                    })
                }
                else -> TrenteSecondaryButton(text = localized("Add Image"), icon = Icons.Default.AddPhotoAlternate, onClick = {
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                })
            }
            TrenteCard(label = localized("Transaction Notes"), icon = Icons.Default.Notes) {
                NotesField(text = request.notes, onTextChange = { model.mutate { request.notes = it } }, isEditing = true, boxed = false)
            }
        }
    }
}

@Composable
private fun RecurrenceStep(model: Observed<NewTransactionViewModel>) {
    val request = model.value.request
    val calendar = TrenteCalendar.current
    val today = calendar.startOfDay(Instant.now())
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
        TrenteCard(label = localized("Recurrence Details"), icon = Icons.Default.CalendarMonth) {
            LabeledPicker(
                title = localized("Frequency"),
                selection = request.recurrenceFrequency,
                options = RecurrenceFrequency.entries,
                onSelect = { model.mutate { request.recurrenceFrequency = it } },
                optionTitle = { it.displayName }
            )
            DateField(label = localized("Start Date"), date = request.recurrenceStartDate, onDateChange = { model.mutate { request.recurrenceStartDate = it } }, minDate = today)
            val endDate = request.recurrenceEndDate
            if (endDate != null) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    DateField(
                        label = localized("End Date"),
                        date = endDate,
                        onDateChange = { model.mutate { request.recurrenceEndDate = it } },
                        minDate = calendar.plusDays(request.recurrenceStartDate, 7),
                        modifier = Modifier.weight(1f)
                    )
                    IconButton(onClick = { model.mutate { request.recurrenceEndDate = null } }) {
                        Icon(Icons.Default.Cancel, contentDescription = localized("Remove End Date"))
                    }
                }
            } else {
                TrentePrimaryButton(text = localized("Add an End Date"), narrow = true, onClick = { model.mutate { request.recurrenceEndDate = request.recurrenceStartDate } })
            }
        }
    }
}
