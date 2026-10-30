package app.trente.data

import app.trente.core.model.BudgetCategory
import app.trente.core.model.MonthRow
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringRuleRow
import app.trente.core.model.StoreBackend
import app.trente.core.model.StoreChanges
import app.trente.core.model.StoreSnapshot
import app.trente.core.model.TransactionEntryRow
import app.trente.core.model.TransactionGroupRow
import app.trente.core.model.TransactionType
import java.io.File
import java.time.Instant
import java.util.UUID
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * Persists the store's graph in Room and the transaction images as files.
 *
 * Writes are queued on one background thread in the order they were saved, so the main thread never waits.
 * Images live in `imagesDirectory/<transaction id>.jpg` and are read only when displayed.
 */
class RoomBackend(
    private val dao: TrenteDao,
    private val imagesDirectory: File,
    private val writer: Executor = Executors.newSingleThreadExecutor { runnable -> Thread(runnable, "trente-store-writer") },
    private val onWritten: () -> Unit = {}
) : StoreBackend {
    override fun load(): StoreSnapshot = StoreSnapshot(
        months = dao.months().map { it.toRow() }.associateBy { it.id },
        groups = dao.transactionGroups().map { it.toRow() }.associateBy { it.id },
        entries = dao.transactionEntries().map { it.toRow() }.associateBy { it.id },
        rules = dao.recurringRules().map { it.toRow() }.associateBy { it.id }
    )

    override fun apply(changes: StoreChanges) {
        if (changes.isEmpty) return
        val entityChanges = EntityChanges(
            months = changes.upsertedMonths.map { it.toEntity() },
            deletedMonthIds = changes.deletedMonthIDs.map { it.toString() },
            groups = changes.upsertedGroups.map { it.toEntity() },
            deletedGroupIds = changes.deletedGroupIDs.map { it.toString() },
            entries = changes.upsertedEntries.map { it.toEntity() },
            deletedEntryIds = changes.deletedEntryIDs.map { it.toString() },
            rules = changes.upsertedRules.map { it.toEntity() },
            deletedRuleIds = changes.deletedRuleIDs.map { it.toString() }
        )
        val imagesToWrite = changes.upsertedGroups.filter { it.imageVersion != null && it.imageData != null }.map { it.id to it.imageData!! }
        val imagesToDelete = changes.upsertedGroups.filter { it.imageVersion == null }.map { it.id } + changes.deletedGroupIDs
        writer.execute {
            dao.applyChanges(entityChanges)
            imagesDirectory.mkdirs()
            imagesToDelete.forEach { imageFile(it).delete() }
            imagesToWrite.forEach { (id, data) -> imageFile(id).writeBytes(data) }
            onWritten()
        }
    }

    override fun loadImage(groupID: UUID): ByteArray? {
        val file = imageFile(groupID)
        return if (file.exists()) file.readBytes() else null
    }

    private fun imageFile(id: UUID) = File(imagesDirectory, "$id.jpg")
}

private fun MonthEntity.toRow() = MonthRow(
    id = UUID.fromString(id),
    startDate = Instant.ofEpochMilli(startDate),
    modifiedDate = modifiedDate?.let(Instant::ofEpochMilli),
    currencyCode = currencyCode,
    idealBudgetCents = idealBudgetCents,
    idealRepartition = decodeRepartition(idealRepartition)
)

private fun MonthRow.toEntity() = MonthEntity(
    id = id.toString(),
    startDate = startDate.toEpochMilli(),
    modifiedDate = modifiedDate?.toEpochMilli(),
    currencyCode = currencyCode,
    idealBudgetCents = idealBudgetCents,
    idealRepartition = encodeRepartition(idealRepartition)
)

private fun TransactionGroupEntity.toRow() = TransactionGroupRow(
    id = UUID.fromString(id),
    addedDate = Instant.ofEpochMilli(addedDate),
    modifiedDate = modifiedDate?.let(Instant::ofEpochMilli),
    title = title,
    type = TransactionType.fromRawValue(type) ?: TransactionType.EXPENSE,
    monthID = monthId?.let(UUID::fromString),
    recurringRuleID = recurringRuleId?.let(UUID::fromString),
    recurringOccurrenceDate = recurringOccurrenceDate?.let(Instant::ofEpochMilli),
    note = note,
    imageVersion = imageVersion
)

private fun TransactionGroupRow.toEntity() = TransactionGroupEntity(
    id = id.toString(),
    addedDate = addedDate.toEpochMilli(),
    modifiedDate = modifiedDate?.toEpochMilli(),
    title = title,
    type = type.rawValue,
    monthId = monthID?.toString(),
    recurringRuleId = recurringRuleID?.toString(),
    recurringOccurrenceDate = recurringOccurrenceDate?.toEpochMilli(),
    note = note,
    imageVersion = imageVersion
)

private fun TransactionEntryEntity.toRow() = TransactionEntryRow(
    id = UUID.fromString(id),
    groupID = groupId?.let(UUID::fromString),
    amountCents = amountCents,
    category = BudgetCategory.fromRawValue(category) ?: BudgetCategory.NEEDS
)

private fun TransactionEntryRow.toEntity() = TransactionEntryEntity(
    id = id.toString(),
    groupId = groupID?.toString(),
    amountCents = amountCents,
    category = category.rawValue
)

private fun RecurringRuleEntity.toRow() = RecurringRuleRow(
    id = UUID.fromString(id),
    title = title,
    frequency = RecurrenceFrequency.fromRawValue(frequency) ?: RecurrenceFrequency.MONTHLY,
    startDate = Instant.ofEpochMilli(startDate),
    endDate = endDate?.let(Instant::ofEpochMilli),
    autoConfirm = autoConfirm,
    repartition = decodeRepartition(repartition),
    createdAt = Instant.ofEpochMilli(createdAt),
    skippedOccurrenceDates = skippedOccurrenceDates.split(',').filter { it.isNotEmpty() }.map { Instant.ofEpochMilli(it.toLong()) },
    lastAutoConfirmedDate = lastAutoConfirmedDate?.let(Instant::ofEpochMilli)
)

private fun RecurringRuleRow.toEntity() = RecurringRuleEntity(
    id = id.toString(),
    title = title,
    frequency = frequency.rawValue,
    startDate = startDate.toEpochMilli(),
    endDate = endDate?.toEpochMilli(),
    autoConfirm = autoConfirm,
    repartition = encodeRepartition(repartition),
    createdAt = createdAt.toEpochMilli(),
    skippedOccurrenceDates = skippedOccurrenceDates.joinToString(",") { it.toEpochMilli().toString() },
    lastAutoConfirmedDate = lastAutoConfirmedDate?.toEpochMilli()
)

/** "needs=125000;wants=75000;savingsAndDebts=50000" */
private fun encodeRepartition(repartition: Map<BudgetCategory, Int>): String =
    repartition.entries.joinToString(";") { "${it.key.rawValue}=${it.value}" }

private fun decodeRepartition(text: String): Map<BudgetCategory, Int> =
    text.split(';').filter { it.contains('=') }.mapNotNull { pair ->
        val (key, value) = pair.split('=', limit = 2)
        val category = BudgetCategory.fromRawValue(key) ?: return@mapNotNull null
        category to (value.toIntOrNull() ?: return@mapNotNull null)
    }.toMap()
