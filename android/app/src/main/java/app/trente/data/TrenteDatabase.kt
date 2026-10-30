package app.trente.data

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.Transaction
import androidx.room.Upsert

@Entity(tableName = "months")
data class MonthEntity(
    @PrimaryKey val id: String,
    val startDate: Long,
    val modifiedDate: Long?,
    val currencyCode: String,
    val idealBudgetCents: Int,
    val idealRepartition: String
)

@Entity(
    tableName = "transaction_groups",
    indices = [Index("monthId"), Index("recurringRuleId"), Index("addedDate")]
)
data class TransactionGroupEntity(
    @PrimaryKey val id: String,
    val addedDate: Long,
    val modifiedDate: Long?,
    val title: String,
    val type: String,
    val monthId: String?,
    val recurringRuleId: String?,
    val recurringOccurrenceDate: Long?,
    val note: String?,
    val imageVersion: String?
)

@Entity(tableName = "transaction_entries", indices = [Index("groupId")])
data class TransactionEntryEntity(
    @PrimaryKey val id: String,
    val groupId: String?,
    val amountCents: Int,
    val category: String
)

@Entity(tableName = "recurring_rules")
data class RecurringRuleEntity(
    @PrimaryKey val id: String,
    val title: String,
    val frequency: String,
    val startDate: Long,
    val endDate: Long?,
    val autoConfirm: Boolean,
    val repartition: String,
    val createdAt: Long,
    val skippedOccurrenceDates: String,
    val lastAutoConfirmedDate: Long?
)

@Dao
abstract class TrenteDao {
    @Query("SELECT * FROM months")
    abstract fun months(): List<MonthEntity>

    @Query("SELECT * FROM transaction_groups")
    abstract fun transactionGroups(): List<TransactionGroupEntity>

    @Query("SELECT * FROM transaction_entries")
    abstract fun transactionEntries(): List<TransactionEntryEntity>

    @Query("SELECT * FROM recurring_rules")
    abstract fun recurringRules(): List<RecurringRuleEntity>

    @Upsert
    abstract fun upsertMonths(months: List<MonthEntity>)

    @Upsert
    abstract fun upsertTransactionGroups(groups: List<TransactionGroupEntity>)

    @Upsert
    abstract fun upsertTransactionEntries(entries: List<TransactionEntryEntity>)

    @Upsert
    abstract fun upsertRecurringRules(rules: List<RecurringRuleEntity>)

    @Query("DELETE FROM months WHERE id IN (:ids)")
    abstract fun deleteMonths(ids: List<String>)

    @Query("DELETE FROM transaction_groups WHERE id IN (:ids)")
    abstract fun deleteTransactionGroups(ids: List<String>)

    @Query("DELETE FROM transaction_entries WHERE id IN (:ids)")
    abstract fun deleteTransactionEntries(ids: List<String>)

    @Query("DELETE FROM recurring_rules WHERE id IN (:ids)")
    abstract fun deleteRecurringRules(ids: List<String>)

    @Transaction
    open fun applyChanges(changes: EntityChanges) {
        if (changes.deletedEntryIds.isNotEmpty()) deleteTransactionEntries(changes.deletedEntryIds)
        if (changes.deletedGroupIds.isNotEmpty()) deleteTransactionGroups(changes.deletedGroupIds)
        if (changes.deletedMonthIds.isNotEmpty()) deleteMonths(changes.deletedMonthIds)
        if (changes.deletedRuleIds.isNotEmpty()) deleteRecurringRules(changes.deletedRuleIds)
        if (changes.months.isNotEmpty()) upsertMonths(changes.months)
        if (changes.rules.isNotEmpty()) upsertRecurringRules(changes.rules)
        if (changes.groups.isNotEmpty()) upsertTransactionGroups(changes.groups)
        if (changes.entries.isNotEmpty()) upsertTransactionEntries(changes.entries)
    }
}

data class EntityChanges(
    val months: List<MonthEntity>,
    val deletedMonthIds: List<String>,
    val groups: List<TransactionGroupEntity>,
    val deletedGroupIds: List<String>,
    val entries: List<TransactionEntryEntity>,
    val deletedEntryIds: List<String>,
    val rules: List<RecurringRuleEntity>,
    val deletedRuleIds: List<String>
)

@Database(
    entities = [MonthEntity::class, TransactionGroupEntity::class, TransactionEntryEntity::class, RecurringRuleEntity::class],
    version = 1,
    exportSchema = true
)
abstract class TrenteDatabase : RoomDatabase() {
    abstract fun dao(): TrenteDao

    companion object {
        const val NAME = "trente.db"

        fun open(context: Context): TrenteDatabase =
            Room.databaseBuilder(context.applicationContext, TrenteDatabase::class.java, NAME).build()

        fun inMemory(context: Context): TrenteDatabase =
            Room.inMemoryDatabaseBuilder(context.applicationContext, TrenteDatabase::class.java).build()
    }
}
