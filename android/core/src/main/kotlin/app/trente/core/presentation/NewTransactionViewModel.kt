package app.trente.core.presentation

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Month
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteStore
import app.trente.core.services.ImageAttachmentLoader
import app.trente.core.services.ImagePreparer
import app.trente.core.services.TransactionCreationRequest
import app.trente.core.services.TransactionService
import app.trente.core.support.NotificationPermissionService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

enum class NewTransactionStep { AMOUNT_CATEGORY, TITLE, REPARTITION, NOTES_IMAGE, RECURRENCE }

/** The state of the new transaction flow. The screen wraps it to observe changes. */
class NewTransactionViewModel(
    private val scope: CoroutineScope,
    private val permissionService: NotificationPermissionService? = null,
    imagePreparer: ImagePreparer = ImagePreparer.identity
) {
    val request = TransactionCreationRequest()

    var step: NewTransactionStep = NewTransactionStep.AMOUNT_CATEGORY
    var isRepartitionComplete: Boolean = false
    var showErrorAlert: Boolean = false
    val imageLoader = ImageAttachmentLoader(scope, imagePreparer)

    var permissionRequest: Job? = null
        private set
    private var repartitionAmountCents: Int? = null

    val filteredSteps: List<NewTransactionStep>
        get() {
            val steps = mutableListOf(NewTransactionStep.AMOUNT_CATEGORY, NewTransactionStep.TITLE)
            if (request.type == TransactionType.INCOME) steps.add(NewTransactionStep.REPARTITION)
            steps.add(NewTransactionStep.NOTES_IMAGE)
            if (request.isRecurrent) steps.add(NewTransactionStep.RECURRENCE)
            return steps
        }

    val showPreviousButton: Boolean get() = step != NewTransactionStep.AMOUNT_CATEGORY

    val isLastStep: Boolean get() = step == filteredSteps.last()

    val canAdvance: Boolean
        get() {
            if (isLastStep && isLoadingImage) return false
            return when (step) {
                NewTransactionStep.AMOUNT_CATEGORY ->
                    request.amountCents != 0 && (request.type == TransactionType.INCOME || request.selectedCategory != null)
                NewTransactionStep.TITLE -> request.title.isNotEmpty()
                NewTransactionStep.REPARTITION -> isRepartitionComplete
                NewTransactionStep.NOTES_IMAGE, NewTransactionStep.RECURRENCE -> true
            }
        }

    val isLoadingImage: Boolean get() = imageLoader.isLoading

    var imageLoadingError: String?
        get() = imageLoader.error
        set(value) {
            imageLoader.error = value
        }

    fun loadImage(loadData: suspend () -> ByteArray?) {
        imageLoader.load(loadData) { preparedData -> request.imageData = preparedData }
    }

    fun nextStep() {
        val currentIndex = filteredSteps.indexOf(step)
        if (currentIndex >= 0 && currentIndex < filteredSteps.size - 1) {
            step = filteredSteps[currentIndex + 1]
        }
        if (step == NewTransactionStep.REPARTITION) {
            prepareRepartition()
        }
    }

    /** Entering the split step starts every category at zero, unless the amount hasn't changed since. */
    private fun prepareRepartition() {
        if (repartitionAmountCents == request.amountCents) return
        request.repartition = BudgetCategory.entries.associateWith { 0 }
        repartitionAmountCents = request.amountCents
    }

    fun previousStep() {
        val currentIndex = filteredSteps.indexOf(step)
        if (currentIndex > 0) {
            step = filteredSteps[currentIndex - 1]
        }
    }

    /** Saves the transaction; a recurring one then asks for the notification permission. */
    fun createTransaction(month: Month, store: TrenteStore): Boolean {
        try {
            TransactionService.create(request, month, store)
        } catch (exception: Exception) {
            showErrorAlert = true
            return false
        }
        val service = permissionService
        if (request.isRecurrent && service != null) {
            permissionRequest = scope.launch { service.requestIfNeeded() }
        }
        return true
    }
}
