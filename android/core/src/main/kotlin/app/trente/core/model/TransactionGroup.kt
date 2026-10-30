package app.trente.core.model

import java.time.Instant
import java.util.UUID

/**
 * One transaction: an expense with a single entry, or an income split into one entry per category.
 *
 * Setting [month] or [recurringRule] keeps the other side of the relationship up to date, like SwiftData's inverses.
 * The image is loaded lazily when it comes from the database, so opening the app doesn't read every photo.
 */
class TransactionGroup(
    title: String,
    type: TransactionType,
    month: Month?,
    note: String?,
    imageAttachmentData: ByteArray?,
    addedDate: Instant = Instant.now(),
    val id: UUID = UUID.randomUUID()
) {
    var addedDate: Instant = addedDate
    var modifiedDate: Instant? = addedDate
    var title: String = title
    var type: TransactionType = type
    var recurringOccurrenceDate: Instant? = null

    // Trente+
    var note: String? = note

    private var loadedImage: ByteArray? = null
    private var isImageLoaded = true
    private var imageSource: (() -> ByteArray?)? = null

    /** Identifies the image's content; null without an image. Changes whenever the image is replaced. */
    var imageVersion: String? = null
        private set

    val hasImageAttachment: Boolean get() = imageVersion != null

    var imageAttachmentData: ByteArray?
        get() {
            if (!isImageLoaded) {
                loadedImage = imageSource?.invoke()
                isImageLoaded = true
            }
            return loadedImage
        }
        set(value) {
            loadedImage = value
            isImageLoaded = true
            imageSource = null
            imageVersion = value?.let { "mem:${it.contentHashCode()}:${it.size}" }
        }

    /** The bytes to persist: only what was set in memory; null leaves the stored image as it is. */
    internal val imageDataToPersist: ByteArray? get() = if (isImageLoaded) loadedImage else null

    /** Used when loading from the database: the image stays on disk until it is displayed. */
    fun attachStoredImage(version: String, source: () -> ByteArray?) {
        loadedImage = null
        isImageLoaded = false
        imageSource = source
        imageVersion = version
    }

    var month: Month? = null
        set(value) {
            if (field === value) return
            field?.mutableGroups?.remove(this)
            field = value
            value?.mutableGroups?.add(this)
        }

    var recurringRule: RecurringTransactionRule? = null
        set(value) {
            if (field === value) return
            field?.mutableTransactions?.remove(this)
            field = value
            value?.mutableTransactions?.add(this)
        }

    internal val mutableEntries = mutableListOf<TransactionEntry>()

    val entries: List<TransactionEntry> get() = mutableEntries

    init {
        this.imageAttachmentData = imageAttachmentData
        this.month = month
    }

    val currency: Currency get() = month?.currency ?: Currency.fallback

    /** The total of every entry in cents, negative for an expense and positive for an income. */
    val totalAmountCents: Int get() = entries.sumOf { it.amountCents }

    val totalAmount: Double get() = totalAmountCents / 100.0

    override fun toString(): String = "TransactionGroup($title, $id)"
}

class TransactionEntry(
    amountCents: Int,
    category: BudgetCategory,
    group: TransactionGroup?,
    val id: UUID = UUID.randomUUID()
) {
    var amountCents: Int = amountCents
    var category: BudgetCategory = category

    var group: TransactionGroup? = null
        set(value) {
            if (field === value) return
            field?.mutableEntries?.remove(this)
            field = value
            value?.mutableEntries?.add(this)
        }

    init {
        this.group = group
    }

    /** The amount, not in cents. Negative for an expense, positive for an income. */
    val amount: Double get() = amountCents / 100.0
}
