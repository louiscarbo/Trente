package app.trente.core.model

import java.time.Instant
import java.util.UUID

/**
 * The in-memory object graph of the app, standing in for SwiftData's `ModelContext`.
 *
 * Months and rules are the roots; transactions are reached through their month, entries through their transaction.
 * [save] compares the graph with what was last saved and hands the difference to the [StoreBackend]
 * (Room in the app, memory in tests). Anything no longer reachable from a root is deleted.
 */
class TrenteStore(private val backend: StoreBackend = InMemoryBackend()) {
    private val mutableMonths = mutableListOf<Month>()
    private val mutableRules = mutableListOf<RecurringTransactionRule>()
    private var lastSaved = StoreSnapshot.empty
    private val listeners = mutableListOf<() -> Unit>()

    val months: List<Month> get() = mutableMonths

    val rules: List<RecurringTransactionRule> get() = mutableRules

    val transactionGroups: List<TransactionGroup> get() = months.flatMap { it.transactionGroups }

    val transactionEntries: List<TransactionEntry> get() = transactionGroups.flatMap { it.entries }

    /** How many times [save] ran. */
    var saveCount: Int = 0
        private set

    /** Bumped on every save, so screens know when to read the graph again. */
    var version: Long = 0
        private set

    val hasChanges: Boolean get() = snapshot() != lastSaved

    fun month(id: UUID): Month? = months.firstOrNull { it.id == id }

    fun rule(id: UUID): RecurringTransactionRule? = rules.firstOrNull { it.id == id }

    fun transactionGroup(id: UUID): TransactionGroup? = transactionGroups.firstOrNull { it.id == id }

    fun insert(month: Month) {
        if (mutableMonths.none { it === month }) mutableMonths.add(month)
    }

    fun insert(rule: RecurringTransactionRule) {
        if (mutableRules.none { it === rule }) mutableRules.add(rule)
    }

    /** Removes the month only; its transactions are left without a month, like SwiftData's nullify rule. */
    fun delete(month: Month) {
        month.transactionGroups.toList().forEach { it.month = null }
        mutableMonths.removeAll { it === month }
    }

    /** Removes the rule; the transactions it created stay, without a rule. */
    fun delete(rule: RecurringTransactionRule) {
        rule.transactions.toList().forEach { it.recurringRule = null }
        mutableRules.removeAll { it === rule }
    }

    /** Removes the transaction and its entries. */
    fun delete(group: TransactionGroup) {
        group.entries.toList().forEach { it.group = null }
        group.month = null
        group.recurringRule = null
    }

    fun delete(entry: TransactionEntry) {
        entry.group = null
    }

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    fun save() {
        val current = snapshot()
        backend.apply(StoreChanges.between(lastSaved, current))
        lastSaved = current
        saveCount += 1
        version += 1
        listeners.toList().forEach { it() }
    }

    fun snapshot(): StoreSnapshot {
        val groups = transactionGroups
        return StoreSnapshot(
            months = months.associate { it.id to it.row() },
            groups = groups.associate { it.id to it.row() },
            entries = groups.flatMap { it.entries }.associate { it.id to it.row() },
            rules = rules.associate { it.id to it.row() }
        )
    }

    companion object {
        /** Builds the graph from what the backend holds. */
        fun load(backend: StoreBackend): TrenteStore {
            val store = TrenteStore(backend)
            val snapshot = backend.load()
            val months = snapshot.months.values.map { row ->
                Month(
                    startDate = row.startDate,
                    currency = Currencies.currency(row.currencyCode) ?: Currency.fallback,
                    idealBudgetCents = row.idealBudgetCents,
                    idealRepartition = row.idealRepartition,
                    id = row.id
                ).also { it.modifiedDate = row.modifiedDate }
            }.associateBy { it.id }
            val rules = snapshot.rules.values.map { row ->
                RecurringTransactionRule(
                    title = row.title,
                    frequency = row.frequency,
                    startDate = row.startDate,
                    endDate = row.endDate,
                    autoConfirm = row.autoConfirm,
                    repartition = row.repartition,
                    createdAt = row.createdAt,
                    id = row.id
                ).also {
                    it.skippedOccurrenceDates = row.skippedOccurrenceDates
                    it.lastAutoConfirmedDate = row.lastAutoConfirmedDate
                }
            }.associateBy { it.id }
            val groups = snapshot.groups.values.mapNotNull { row ->
                val month = months[row.monthID] ?: return@mapNotNull null
                TransactionGroup(
                    title = row.title,
                    type = row.type,
                    month = month,
                    note = row.note,
                    imageAttachmentData = null,
                    addedDate = row.addedDate,
                    id = row.id
                ).also {
                    val version = row.imageVersion
                    if (version != null) {
                        val data = row.imageData
                        if (data != null) it.imageAttachmentData = data else it.attachStoredImage(version) { backend.loadImage(row.id) }
                    }
                    it.modifiedDate = row.modifiedDate
                    it.recurringRule = row.recurringRuleID?.let(rules::get)
                    it.recurringOccurrenceDate = row.recurringOccurrenceDate
                }
            }.associateBy { it.id }
            for (row in snapshot.entries.values) {
                val group = groups[row.groupID] ?: continue
                TransactionEntry(amountCents = row.amountCents, category = row.category, group = group, id = row.id)
            }
            months.values.sortedBy { it.startDate }.forEach(store::insert)
            rules.values.sortedBy { it.createdAt }.forEach(store::insert)
            store.lastSaved = store.snapshot()
            return store
        }
    }
}

private fun Month.row() = MonthRow(id, startDate, modifiedDate, currency.isoCode, idealBudgetCents, idealRepartition)

private fun TransactionGroup.row() = TransactionGroupRow(
    id = id,
    addedDate = addedDate,
    modifiedDate = modifiedDate,
    title = title,
    type = type,
    monthID = month?.id,
    recurringRuleID = recurringRule?.id,
    recurringOccurrenceDate = recurringOccurrenceDate,
    note = note,
    imageVersion = imageVersion,
    imageData = imageDataToPersist
)

private fun TransactionEntry.row() = TransactionEntryRow(id, group?.id, amountCents, category)

private fun RecurringTransactionRule.row() = RecurringRuleRow(
    id = id,
    title = title,
    frequency = frequency,
    startDate = startDate,
    endDate = endDate,
    autoConfirm = autoConfirm,
    repartition = repartition,
    createdAt = createdAt,
    skippedOccurrenceDates = skippedOccurrenceDates,
    lastAutoConfirmedDate = lastAutoConfirmedDate
)

/** What the backend stores for a month. */
data class MonthRow(
    val id: UUID,
    val startDate: Instant,
    val modifiedDate: Instant?,
    val currencyCode: String,
    val idealBudgetCents: Int,
    val idealRepartition: Map<BudgetCategory, Int>
)

/**
 * What the backend stores for a transaction. [imageData] is not part of equality: [imageVersion] is.
 * It holds the bytes only when they were set in memory; null means "keep the stored image".
 */
class TransactionGroupRow(
    val id: UUID,
    val addedDate: Instant,
    val modifiedDate: Instant?,
    val title: String,
    val type: TransactionType,
    val monthID: UUID?,
    val recurringRuleID: UUID?,
    val recurringOccurrenceDate: Instant?,
    val note: String?,
    val imageVersion: String?,
    val imageData: ByteArray? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TransactionGroupRow) return false
        return id == other.id &&
            addedDate == other.addedDate &&
            modifiedDate == other.modifiedDate &&
            title == other.title &&
            type == other.type &&
            monthID == other.monthID &&
            recurringRuleID == other.recurringRuleID &&
            recurringOccurrenceDate == other.recurringOccurrenceDate &&
            note == other.note &&
            imageVersion == other.imageVersion
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + addedDate.hashCode()
        result = 31 * result + (modifiedDate?.hashCode() ?: 0)
        result = 31 * result + title.hashCode()
        result = 31 * result + type.hashCode()
        result = 31 * result + (monthID?.hashCode() ?: 0)
        result = 31 * result + (recurringRuleID?.hashCode() ?: 0)
        result = 31 * result + (recurringOccurrenceDate?.hashCode() ?: 0)
        result = 31 * result + (note?.hashCode() ?: 0)
        result = 31 * result + (imageVersion?.hashCode() ?: 0)
        return result
    }
}

data class TransactionEntryRow(
    val id: UUID,
    val groupID: UUID?,
    val amountCents: Int,
    val category: BudgetCategory
)

data class RecurringRuleRow(
    val id: UUID,
    val title: String,
    val frequency: RecurrenceFrequency,
    val startDate: Instant,
    val endDate: Instant?,
    val autoConfirm: Boolean,
    val repartition: Map<BudgetCategory, Int>,
    val createdAt: Instant,
    val skippedOccurrenceDates: List<Instant>,
    val lastAutoConfirmedDate: Instant?
)

data class StoreSnapshot(
    val months: Map<UUID, MonthRow>,
    val groups: Map<UUID, TransactionGroupRow>,
    val entries: Map<UUID, TransactionEntryRow>,
    val rules: Map<UUID, RecurringRuleRow>
) {
    companion object {
        val empty = StoreSnapshot(emptyMap(), emptyMap(), emptyMap(), emptyMap())
    }
}

/** The rows to write and the ids to delete between two snapshots. */
data class StoreChanges(
    val upsertedMonths: List<MonthRow>,
    val deletedMonthIDs: Set<UUID>,
    val upsertedGroups: List<TransactionGroupRow>,
    val deletedGroupIDs: Set<UUID>,
    val upsertedEntries: List<TransactionEntryRow>,
    val deletedEntryIDs: Set<UUID>,
    val upsertedRules: List<RecurringRuleRow>,
    val deletedRuleIDs: Set<UUID>
) {
    val isEmpty: Boolean
        get() = upsertedMonths.isEmpty() && deletedMonthIDs.isEmpty() &&
            upsertedGroups.isEmpty() && deletedGroupIDs.isEmpty() &&
            upsertedEntries.isEmpty() && deletedEntryIDs.isEmpty() &&
            upsertedRules.isEmpty() && deletedRuleIDs.isEmpty()

    companion object {
        fun between(before: StoreSnapshot, after: StoreSnapshot): StoreChanges = StoreChanges(
            upsertedMonths = changed(before.months, after.months),
            deletedMonthIDs = before.months.keys - after.months.keys,
            upsertedGroups = changed(before.groups, after.groups),
            deletedGroupIDs = before.groups.keys - after.groups.keys,
            upsertedEntries = changed(before.entries, after.entries),
            deletedEntryIDs = before.entries.keys - after.entries.keys,
            upsertedRules = changed(before.rules, after.rules),
            deletedRuleIDs = before.rules.keys - after.rules.keys
        )

        private fun <Row> changed(before: Map<UUID, Row>, after: Map<UUID, Row>): List<Row> =
            after.filter { (id, row) -> before[id] != row }.values.toList()
    }
}

interface StoreBackend {
    fun load(): StoreSnapshot

    fun apply(changes: StoreChanges)

    /** The stored image of a transaction, read on demand. */
    fun loadImage(groupID: UUID): ByteArray?
}

/** Keeps everything in memory: tests, previews and the debug build. */
class InMemoryBackend(initial: StoreSnapshot = StoreSnapshot.empty) : StoreBackend {
    var snapshot: StoreSnapshot = initial
        private set

    override fun load(): StoreSnapshot = snapshot

    override fun apply(changes: StoreChanges) {
        val groups = changes.upsertedGroups.map { row ->
            // A row without bytes keeps the image stored before.
            if (row.imageVersion != null && row.imageData == null) row.withImageData(snapshot.groups[row.id]?.imageData) else row
        }
        snapshot = StoreSnapshot(
            months = (snapshot.months - changes.deletedMonthIDs) + changes.upsertedMonths.associateBy { it.id },
            groups = (snapshot.groups - changes.deletedGroupIDs) + groups.associateBy { it.id },
            entries = (snapshot.entries - changes.deletedEntryIDs) + changes.upsertedEntries.associateBy { it.id },
            rules = (snapshot.rules - changes.deletedRuleIDs) + changes.upsertedRules.associateBy { it.id }
        )
    }

    override fun loadImage(groupID: UUID): ByteArray? = snapshot.groups[groupID]?.imageData

    private fun TransactionGroupRow.withImageData(data: ByteArray?) = TransactionGroupRow(
        id, addedDate, modifiedDate, title, type, monthID, recurringRuleID, recurringOccurrenceDate, note, imageVersion, data
    )
}
