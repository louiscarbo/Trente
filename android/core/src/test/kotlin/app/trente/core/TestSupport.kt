package app.trente.core

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Currencies
import app.trente.core.model.Currency
import app.trente.core.model.Month
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.support.NotificationAuthorizing
import app.trente.core.support.NotificationPermissionStatus
import java.time.ZoneId

val EUR: Currency = Currencies.currency("EUR")!!

val PARIS: ZoneId = ZoneId.of("Europe/Paris")

fun parisCalendar() = TrenteCalendar(PARIS)

fun makeStore() = TrenteStore()

fun insertMonth(year: Int, month: Int, store: TrenteStore): Month {
    val inserted = Month(
        startDate = TrenteCalendar.current.date(year, month, 1),
        currency = EUR,
        idealBudgetCents = 2000_00,
        idealRepartition = mapOf(
            BudgetCategory.NEEDS to 50,
            BudgetCategory.WANTS to 30,
            BudgetCategory.SAVINGS_AND_DEBTS to 20
        )
    )
    store.insert(inserted)
    return inserted
}

fun csvRecords(csv: String, separator: Char = ','): List<List<String>> {
    val records = mutableListOf<List<String>>()
    var record = mutableListOf<String>()
    val field = StringBuilder()
    var isQuoted = false
    var index = 0
    while (index < csv.length) {
        val character = csv[index]
        when {
            isQuoted -> {
                if (character != '"') {
                    field.append(character)
                } else if (index + 1 < csv.length && csv[index + 1] == '"') {
                    field.append('"')
                    index += 1
                } else {
                    isQuoted = false
                }
            }
            character == '"' -> isQuoted = true
            character == separator -> {
                record.add(field.toString())
                field.clear()
            }
            character == '\r' && index + 1 < csv.length && csv[index + 1] == '\n' -> {
                record.add(field.toString())
                records.add(record)
                record = mutableListOf()
                field.clear()
                index += 1
            }
            else -> field.append(character)
        }
        index += 1
    }
    if (field.isNotEmpty() || record.isNotEmpty()) {
        record.add(field.toString())
        records.add(record)
    }
    return records
}

class FakeNotificationCenter(
    private val status: NotificationPermissionStatus,
    private val grants: Boolean
) : NotificationAuthorizing {
    var requestCount = 0
        private set

    override suspend fun currentStatus(): NotificationPermissionStatus = status

    override suspend fun requestAuthorization(): Boolean {
        requestCount += 1
        return grants
    }
}
