package app.trente.core.services.export

import app.trente.core.PARIS
import app.trente.core.csvRecords
import app.trente.core.insertMonth
import app.trente.core.makeStore
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetCategory.NEEDS
import app.trente.core.model.BudgetCategory.SAVINGS_AND_DEBTS
import app.trente.core.model.BudgetCategory.WANTS
import app.trente.core.model.Month
import app.trente.core.model.RecurrenceFrequency
import app.trente.core.model.RecurringTransactionRule
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteStore
import app.trente.core.parisCalendar
import app.trente.core.services.RecurringTransactionService
import java.io.File
import java.nio.file.Files
import java.time.Instant
import java.time.ZoneOffset
import java.util.Locale
import java.util.UUID
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

private val transactionID1: UUID = UUID.fromString("00000000-0000-0000-0000-000000000001")

class TransactionCSVFormatTests {
    private val calendar = parisCalendar()
    private val european = TransactionCSVFormat(style = TransactionCSVFormat.Style.EUROPEAN)

    private fun row(title: String = "Groceries", note: String? = "Market") = TransactionExportRow(
        date = calendar.date(2026, 10, 5, 12),
        monthStartDate = calendar.date(2026, 10, 1),
        title = title,
        type = TransactionType.EXPENSE,
        category = NEEDS,
        amountCents = -12_50,
        currencyCode = "EUR",
        isRecurring = false,
        note = note,
        transactionID = transactionID1
    )

    private fun lines(csv: String) = csv.split("\r\n").dropLast(1)

    @Test
    fun europeanStyle() {
        val csv = TransactionCSVBuilder.csv(listOf(row()), european, zone = PARIS)

        assertEquals(
            listOf(
                "Date;Month;Title;Type;Category;Amount;Currency;Recurring;Note;Transaction ID",
                "2026-10-05;2026-10;Groceries;expense;Needs;-12,50;EUR;;Market;00000000-0000-0000-0000-000000000001"
            ),
            lines(csv)
        )
    }

    @Test
    fun styleFollowsRegion() {
        assertEquals(TransactionCSVFormat.Style.STANDARD, TransactionCSVFormat.Style.of(Locale.US))
        assertEquals(TransactionCSVFormat.Style.STANDARD, TransactionCSVFormat.Style.of(Locale.UK))
        assertEquals(TransactionCSVFormat.Style.EUROPEAN, TransactionCSVFormat.Style.of(Locale.FRANCE))
        assertEquals(TransactionCSVFormat.Style.EUROPEAN, TransactionCSVFormat.Style.of(Locale.GERMANY))
    }

    @Test
    fun quotesSeparator() {
        assertEquals("\"Rent; flat\"", TransactionCSVBuilder.escaped("Rent; flat", ";"))
        assertEquals("Rent, flat", TransactionCSVBuilder.escaped("Rent, flat", ";"))
        assertEquals("Rent; flat", TransactionCSVBuilder.escaped("Rent; flat"))
    }

    @Test
    fun withoutNotes() {
        val csv = TransactionCSVBuilder.csv(listOf(row()), TransactionCSVFormat(includesNotes = false), zone = PARIS)

        assertEquals(
            listOf(
                "Date,Month,Title,Type,Category,Amount,Currency,Recurring,Transaction ID",
                "2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,,00000000-0000-0000-0000-000000000001"
            ),
            lines(csv)
        )
    }

    @Test
    fun imageColumn() {
        val imagePaths = mapOf(row().transactionID to "Images/2026-10-05 Groceries 00000000.jpg")

        val csv = TransactionCSVBuilder.csv(listOf(row()), imagePaths = imagePaths, zone = PARIS)

        assertEquals(
            listOf(
                "Date,Month,Title,Type,Category,Amount,Currency,Recurring,Note,Image,Transaction ID",
                "2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,,Market,Images/2026-10-05 Groceries 00000000.jpg,00000000-0000-0000-0000-000000000001"
            ),
            lines(csv)
        )
    }

    @Test
    fun europeanImageColumnWithoutNotes() {
        val format = TransactionCSVFormat(style = TransactionCSVFormat.Style.EUROPEAN, includesNotes = false)

        val csv = TransactionCSVBuilder.csv(listOf(row()), format, imagePaths = emptyMap(), zone = PARIS)

        assertEquals(
            listOf(
                "Date;Month;Title;Type;Category;Amount;Currency;Recurring;Image;Transaction ID",
                "2026-10-05;2026-10;Groceries;expense;Needs;-12,50;EUR;;;00000000-0000-0000-0000-000000000001"
            ),
            lines(csv)
        )
    }

    @Test
    fun noImageColumn() {
        assertFalse(lines(TransactionCSVBuilder.csv(listOf(row()), zone = PARIS)).first().contains("Image"))
    }

    @Test
    fun europeanRowWithSemicolons() {
        val csv = TransactionCSVBuilder.csv(listOf(row(title = "Rent; flat", note = "Paid; late")), european, zone = PARIS)

        val records = csvRecords(csv, ';')

        assertEquals(2, records.size)
        assertTrue(records.all { it.size == 10 })
        assertEquals("Rent; flat", records.last()[2])
        assertEquals("Paid; late", records.last()[8])
    }

    @Test
    fun fileUsesFormat() {
        val file = TransactionsCSVFile(monthIDs = emptyList(), fileName = "Trente 2026-10", format = european)

        val text = file.csvData(listOf(row())).drop(3).toByteArray().toString(Charsets.UTF_8)

        assertEquals(TransactionCSVBuilder.csv(listOf(row()), european), text)
    }
}

class TransactionCSVBuilderTests {
    private val calendar = parisCalendar()
    private val headerLine = "Date,Month,Title,Type,Category,Amount,Currency,Recurring,Note,Transaction ID\r\n"

    private fun date(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) = calendar.date(year, month, day, hour, minute)

    private fun row(
        title: String = "Groceries",
        date: Instant? = null,
        type: TransactionType = TransactionType.EXPENSE,
        category: BudgetCategory = NEEDS,
        amountCents: Int = -12_50,
        isRecurring: Boolean = false,
        note: String? = null,
        transactionID: UUID = transactionID1
    ) = TransactionExportRow(
        date = date ?: this.date(2026, 10, 5),
        monthStartDate = this.date(2026, 10, 1, hour = 0),
        title = title,
        type = type,
        category = category,
        amountCents = amountCents,
        currencyCode = "EUR",
        isRecurring = isRecurring,
        note = note,
        transactionID = transactionID
    )

    private fun dataLines(csv: String) = csv.split("\r\n").drop(1).dropLast(1)
    private fun dataRecords(csv: String) = csvRecords(csv).drop(1)

    @Test
    fun emptyInputGivesHeader() {
        assertEquals(headerLine, TransactionCSVBuilder.csv(emptyList(), zone = PARIS))
    }

    @Test
    fun rowListsEveryColumn() {
        val csv = TransactionCSVBuilder.csv(listOf(row(isRecurring = true, note = "Weekly")), zone = PARIS)

        assertEquals(headerLine + "2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,yes,Weekly,00000000-0000-0000-0000-000000000001\r\n", csv)
    }

    @Test
    fun emptyRecurringAndNote() {
        val lines = dataLines(TransactionCSVBuilder.csv(listOf(row()), zone = PARIS))

        assertEquals(listOf("2026-10-05,2026-10,Groceries,expense,Needs,-12.50,EUR,,,00000000-0000-0000-0000-000000000001"), lines)
    }

    @Test
    fun formatsAmount() {
        val cases = listOf(
            0L to "0.00",
            5L to "0.05",
            -5L to "-0.05",
            -50L to "-0.50",
            100L to "1.00",
            -12_50L to "-12.50",
            1_234_567_89L to "1234567.89",
            -9_999_999_999_99L to "-9999999999.99",
            Long.MAX_VALUE to "92233720368547758.07",
            Long.MIN_VALUE to "-92233720368547758.08"
        )
        for ((cents, expected) in cases) {
            assertEquals(expected, TransactionCSVBuilder.amountText(cents))
        }
    }

    @Test
    fun quotesFields() {
        val cases = listOf(
            "Plain" to "Plain",
            "" to "",
            "Rent, flat" to "\"Rent, flat\"",
            "The \"best\" pizza" to "\"The \"\"best\"\" pizza\"",
            "Line\nbreak" to "\"Line\nbreak\"",
            "Line\r\nbreak" to "\"Line\r\nbreak\"",
            "Carriage\rreturn" to "\"Carriage\rreturn\"",
            "Café ☕️" to "Café ☕️"
        )
        for ((field, expected) in cases) {
            assertEquals(expected, TransactionCSVBuilder.escaped(field))
        }
    }

    @Test
    fun escapesInsideRow() {
        val records = dataRecords(TransactionCSVBuilder.csv(listOf(row(title = "Dinner, \"Chez Paul\"", note = "With Anna\nand Tom")), zone = PARIS))

        assertEquals(1, records.size)
        val record = records.first()
        assertEquals(10, record.size)
        assertEquals("Dinner, \"Chez Paul\"", record[2])
        assertEquals("With Anna\nand Tom", record[8])
    }

    @Test
    fun neutralizesFormulas() {
        val cases = listOf(
            "=SUM(A1:A9)" to "'=SUM(A1:A9)",
            "+33 6 12 34 56 78" to "'+33 6 12 34 56 78",
            "-Refund" to "'-Refund",
            "@Mention" to "'@Mention",
            "\tTabbed" to "'\tTabbed",
            "\r\nLine" to "'\r\nLine",
            "Plain = text" to "Plain = text",
            "" to ""
        )
        for ((text, expected) in cases) {
            assertEquals(expected, TransactionCSVBuilder.neutralized(text))
        }
    }

    @Test
    fun neutralizesTitleAndNoteOnly() {
        val records = dataRecords(TransactionCSVBuilder.csv(listOf(row(title = "=HYPERLINK(\"http://example.com\")", note = "-Refund")), zone = PARIS))

        val record = records.first()
        assertEquals("'=HYPERLINK(\"http://example.com\")", record[2])
        assertEquals("-12.50", record[5])
        assertEquals("'-Refund", record[8])
    }

    @Test
    fun datesAroundMidnight() {
        for ((hour, minute) in listOf(0 to 0, 0 to 1, 23 to 59)) {
            val added = date(2026, 10, 1, hour, minute)
            val lines = dataLines(TransactionCSVBuilder.csv(listOf(row(date = added)), zone = PARIS))

            assertTrue(lines.first().startsWith("2026-10-01,2026-10,"))
        }
    }

    @Test
    fun midnightInOtherTimeZone() {
        val added = date(2026, 10, 1, hour = 0)
        val lines = dataLines(TransactionCSVBuilder.csv(listOf(row(date = added)), zone = ZoneOffset.UTC))

        assertTrue(lines.first().startsWith("2026-09-30,2026-09,"))
    }

    @Test
    fun monthTextPadsMonth() {
        assertEquals("2026-03", TransactionCSVBuilder.monthText(date(2026, 3, 1, hour = 0), PARIS))
    }

    @Test
    fun incomeSplitGivesRows() {
        val salaryID = UUID.randomUUID()
        val rows = listOf(
            row(title = "Salary", type = TransactionType.INCOME, category = SAVINGS_AND_DEBTS, amountCents = 400_00, transactionID = salaryID),
            row(title = "Salary", type = TransactionType.INCOME, category = NEEDS, amountCents = 1000_00, transactionID = salaryID),
            row(title = "Salary", type = TransactionType.INCOME, category = WANTS, amountCents = 600_00, transactionID = salaryID)
        )

        val records = dataRecords(TransactionCSVBuilder.csv(rows, zone = PARIS))

        assertEquals(3, records.size)
        assertTrue(records.all { it[9] == salaryID.toString().uppercase() && it[3] == "income" })
        assertEquals(listOf("Needs", "Wants", "Savings and Debts"), records.map { it[4] })
        assertEquals(listOf("1000.00", "600.00", "400.00"), records.map { it[5] })
    }

    @Test
    fun incomeSplitRepeatsImagePath() {
        val salaryID = UUID.randomUUID()
        val rows = listOf(
            row(title = "Salary", type = TransactionType.INCOME, category = NEEDS, amountCents = 1000_00, transactionID = salaryID),
            row(title = "Salary", type = TransactionType.INCOME, category = WANTS, amountCents = 600_00, transactionID = salaryID),
            row(title = "Taxi", date = date(2026, 10, 6), transactionID = UUID.randomUUID())
        )
        val path = "Images/2026-10-05 Salary ${salaryID.toString().uppercase().take(8)}.jpg"

        val records = dataRecords(TransactionCSVBuilder.csv(rows, imagePaths = mapOf(salaryID to path), zone = PARIS))

        assertEquals(listOf(path, path, ""), records.map { it[9] })
    }

    @Test
    fun sortsByDateThenTitle() {
        val rows = listOf(
            row(title = "Taxi", date = date(2026, 10, 7), transactionID = UUID.randomUUID()),
            row(title = "coffee", date = date(2026, 10, 5), transactionID = UUID.randomUUID()),
            row(title = "Bakery", date = date(2026, 10, 5), transactionID = UUID.randomUUID()),
            row(title = "Rent", date = date(2026, 10, 1), transactionID = UUID.randomUUID())
        )

        val titles = dataRecords(TransactionCSVBuilder.csv(rows, zone = PARIS)).map { it[2] }

        assertEquals(listOf("Rent", "Bakery", "coffee", "Taxi"), titles)
    }

    @Test
    fun usesCRLF() {
        val csv = TransactionCSVBuilder.csv(listOf(row(), row(title = "Taxi")), zone = PARIS)

        assertTrue(csv.endsWith("\r\n"))
        assertEquals(4, csv.split("\r\n").size)
        assertFalse(csv.replace("\r\n", "").contains("\n"))
    }
}

class TransactionExportRowTests {
    private val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte(), 0x00, 0x10)

    private fun insertGroup(
        title: String,
        type: TransactionType,
        amounts: Map<BudgetCategory, Int>,
        image: ByteArray? = null,
        month: Month
    ): TransactionGroup {
        val group = TransactionGroup(title = title, type = type, month = month, note = "Note $title", imageAttachmentData = image)
        amounts.forEach { (category, amountCents) -> TransactionEntry(amountCents, category, group) }
        return group
    }

    @Test
    fun mapsEntriesToRows() {
        val store = makeStore()
        val october = insertMonth(2026, 10, store)
        val november = insertMonth(2026, 11, store)
        val coffee = insertGroup("Coffee", TransactionType.EXPENSE, mapOf(WANTS to -3_50), month = october)
        val salary = insertGroup("Salary", TransactionType.INCOME, mapOf(NEEDS to 1000_00, WANTS to 600_00, SAVINGS_AND_DEBTS to 400_00), month = november)
        store.save()

        val rows = TransactionExportRow.rows(listOf(october, november))

        assertEquals(4, rows.size)
        val coffeeRow = rows.first { it.transactionID == coffee.id }
        assertEquals("Coffee", coffeeRow.title)
        assertEquals(TransactionType.EXPENSE, coffeeRow.type)
        assertEquals(WANTS, coffeeRow.category)
        assertEquals(-3_50, coffeeRow.amountCents)
        assertEquals("EUR", coffeeRow.currencyCode)
        assertEquals("Note Coffee", coffeeRow.note)
        assertEquals(coffee.addedDate, coffeeRow.date)
        assertEquals(october.startDate, coffeeRow.monthStartDate)
        assertFalse(coffeeRow.isRecurring)

        val salaryRows = rows.filter { it.transactionID == salary.id }
        assertEquals(listOf(400_00, 600_00, 1000_00), salaryRows.map { it.amountCents }.sorted())
        assertTrue(salaryRows.all { it.monthStartDate == november.startDate })
    }

    @Test
    fun recurringFlagSurvivesRuleDeletion() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val rule = RecurringTransactionRule(
            title = "Rent",
            frequency = RecurrenceFrequency.MONTHLY,
            startDate = month.startDate,
            repartition = mapOf(NEEDS to -800_00),
            createdAt = month.startDate
        )
        store.insert(rule)
        val rent = insertGroup("Rent", TransactionType.EXPENSE, mapOf(NEEDS to -800_00), month = month)
        rent.recurringRule = rule
        rent.recurringOccurrenceDate = month.startDate
        store.save()

        RecurringTransactionService.delete(rule, store)
        store.save()

        assertNull(rent.recurringRule)
        assertEquals(listOf(true), TransactionExportRow.rows(listOf(month)).map { it.isRecurring })
    }

    @Test
    fun emptyMonthGivesNoRows() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)

        assertTrue(TransactionExportRow.rows(listOf(month)).isEmpty())
    }

    @Test
    fun rowsReferenceImages() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val coffee = insertGroup("Coffee", TransactionType.EXPENSE, mapOf(WANTS to -3_50), month = month)
        val salary = insertGroup("Salary", TransactionType.INCOME, mapOf(NEEDS to 1000_00, WANTS to 600_00), image = jpeg, month = month)
        store.save()

        val rows = TransactionExportRow.rows(listOf(month), TransactionExportRow.groupsWithImages(store))

        assertEquals(listOf(salary.id, salary.id), rows.filter { it.transactionID == salary.id }.map { it.imageSourceID })
        assertNull(rows.first { it.transactionID == coffee.id }.imageSourceID)
        assertEquals(listOf(salary.id), TransactionExportImage.rowsWithImages(rows).map { it.transactionID })
    }

    @Test
    fun rowsWithoutImageList() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        insertGroup("Coffee", TransactionType.EXPENSE, mapOf(WANTS to -3_50), image = jpeg, month = month)
        store.save()

        assertTrue(TransactionExportRow.rows(listOf(month)).all { it.imageSourceID == null })
    }

    @Test
    fun writesImages() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val salary = insertGroup("Salary", TransactionType.INCOME, mapOf(NEEDS to 1000_00, WANTS to 600_00), image = jpeg, month = month)
        val taxi = insertGroup("Taxi", TransactionType.EXPENSE, mapOf(WANTS to -20_00), image = jpeg, month = month)
        store.save()
        val rows = TransactionExportRow.rows(listOf(month), TransactionExportRow.groupsWithImages(store))
        taxi.imageAttachmentData = null
        store.save()
        val folder = Files.createTempDirectory("trente-images").toFile()
        try {
            val paths = TransactionExportImage.writeImages(rows, folder) { id -> store.transactionGroups.firstOrNull { it.id == id }?.imageAttachmentData }

            val fileName = TransactionExportImage.fileName(salary.addedDate, "Salary", salary.id, jpeg)
            assertEquals(mapOf(salary.id to "Images/$fileName"), paths)
            assertTrue(File(folder, fileName).readBytes().contentEquals(jpeg))
            assertEquals(listOf(fileName), folder.list()!!.toList())
        } finally {
            folder.deleteRecursively()
        }
    }
}

class TransactionsCSVFileTests {
    private val calendar = parisCalendar()
    private val png = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

    private fun month(year: Int, month: Int) = calendar.date(year, month, 1)

    private fun insertGroup(title: String, image: ByteArray? = null, month: Month): TransactionGroup {
        val group = TransactionGroup(title = title, type = TransactionType.EXPENSE, month = month, note = null, imageAttachmentData = image)
        TransactionEntry(-12_50, NEEDS, group)
        return group
    }

    private fun imageData(store: TrenteStore): (UUID) -> ByteArray? = { id -> store.transactionGroups.firstOrNull { it.id == id }?.imageAttachmentData }

    private fun text(data: ByteArray) = data.drop(3).toByteArray().toString(Charsets.UTF_8)

    private fun makeFolder(): File = Files.createTempDirectory("trente-export").toFile()

    @Test
    fun dataStartsWithByteOrderMark() {
        val data = TransactionsCSVFile(monthIDs = emptyList(), fileName = "Trente 2026-10").csvData(emptyList())

        assertEquals(listOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte()), data.take(3))
        assertEquals(TransactionCSVBuilder.csv(emptyList()), text(data))
    }

    @Test
    fun monthFileName() {
        val store = makeStore()
        val month = insertMonth(2026, 3, store)

        assertEquals("Trente 2026-03", TransactionsCSVFile.fileName(month))
        assertEquals("Trente 2026-03.csv", TransactionsCSVFile(monthIDs = listOf(month.id), fileName = "Trente 2026-03").csvFileName)
    }

    @Test
    fun everyMonthFileName() {
        val name = TransactionsCSVFile.fileName(listOf(month(2026, 9), month(2026, 10)), includesEveryMonth = true, zone = PARIS)

        assertEquals(TransactionsCSVFile.allMonthsFileName, name)
    }

    @Test
    fun selectionFileName() {
        val name = TransactionsCSVFile.fileName(listOf(month(2026, 10), month(2026, 6), month(2026, 8)), includesEveryMonth = false, zone = PARIS)

        assertEquals("Trente 2026-06 – 2026-10", name)
    }

    @Test
    fun singleMonthSelectionFileName() {
        val name = TransactionsCSVFile.fileName(listOf(month(2026, 10)), includesEveryMonth = false, zone = PARIS)

        assertEquals("Trente 2026-10", name)
    }

    @Test
    fun writesAZip() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        insertGroup("Groceries", png, month)
        store.save()
        val file = TransactionsCSVFile(monthIDs = listOf(month.id), fileName = "Trente 2026-10", hasImages = true)
        val exports = makeFolder()
        try {
            val written = file.write(store, exports)
            val directory = written.parentFile

            assertEquals("Trente 2026-10.zip", written.name)
            assertEquals(listOf(0x50.toByte(), 0x4B, 0x03, 0x04), written.readBytes().take(4))
            assertEquals(listOf("Trente 2026-10.zip"), directory.list()!!.toList())
        } finally {
            exports.deleteRecursively()
        }
    }

    @Test
    fun writesACSV() {
        for ((includesImages, hasImages) in listOf(false to true, true to false)) {
            val store = makeStore()
            val month = insertMonth(2026, 10, store)
            insertGroup("Groceries", png, month)
            store.save()
            val file = TransactionsCSVFile(
                monthIDs = listOf(month.id),
                fileName = "Trente 2026-10",
                format = TransactionCSVFormat(includesImages = includesImages),
                hasImages = hasImages
            )
            val exports = makeFolder()
            try {
                val written = file.write(store, exports)

                val records = csvRecords(text(written.readBytes()))
                assertEquals("Trente 2026-10.csv", written.name)
                assertEquals(2, records.size)
                assertFalse(records.first().contains("Image"))
            } finally {
                exports.deleteRecursively()
            }
        }
    }

    @Test
    fun rowsComeFromSelectedMonths() {
        val store = makeStore()
        val october = insertMonth(2026, 10, store)
        val november = insertMonth(2026, 11, store)
        val groceries = insertGroup("Groceries", png, october)
        insertGroup("Taxi", month = november)
        store.save()
        val file = TransactionsCSVFile(monthIDs = listOf(october.id), fileName = "Trente 2026-10")

        val rows = file.rows(store)

        assertEquals(listOf(groceries.id), rows.map { it.transactionID })
        assertEquals(listOf(groceries.id), rows.map { it.imageSourceID })
    }

    @Test
    fun folderHoldsCSVAndImages() {
        val store = makeStore()
        val month = insertMonth(2026, 10, store)
        val group = insertGroup("Groceries", png, month)
        store.save()
        val rows = TransactionExportRow.rows(listOf(month), TransactionExportRow.groupsWithImages(store))
        val file = TransactionsCSVFile(monthIDs = emptyList(), fileName = "Trente 2026-10", hasImages = true)
        val directory = makeFolder()
        try {
            val folder = file.writeFolder(rows, directory, imageData(store))

            val records = csvRecords(text(File(folder, file.csvFileName).readBytes()))
            val imageColumn = records.first().indexOf("Image")
            val imagePath = records.last()[imageColumn]
            val expectedName = TransactionExportImage.fileName(group.addedDate, "Groceries", group.id, png)
            assertEquals(2, records.size)
            assertEquals("Images/$expectedName", imagePath)
            assertTrue(File(folder, imagePath).readBytes().contentEquals(png))
        } finally {
            directory.deleteRecursively()
        }
    }

    @Test
    fun newExportRemovesPreviousFiles() {
        val file = TransactionsCSVFile(monthIDs = emptyList(), fileName = "Trente 2026-10")
        val exports = makeFolder()
        try {
            val first = file.writeCSV(emptyList(), exports)
            val second = file.writeCSV(emptyList(), exports)

            assertFalse(first.exists())
            assertTrue(second.exists())
        } finally {
            exports.deleteRecursively()
        }
    }
}

class TransactionExportImageTests {
    private val calendar = parisCalendar()
    private val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 0xFF.toByte(), 0xE0.toByte(), 0x00, 0x10)
    private val png = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)

    private fun isoMedia(brand: String) = byteArrayOf(0, 0, 0, 0x18) + "ftyp$brand".toByteArray() + byteArrayOf(0, 0, 0, 0)

    @Test
    fun sanitizesTitle() {
        val cases = listOf(
            "Groceries" to "Groceries",
            "Rent: flat/2" to "Rent- flat-2",
            "A\\B*C?D\"E<F>G|H" to "A-B-C-D-E-F-G-H",
            "Line\nbreak" to "Line-break",
            "  Lots   of \t space  " to "Lots of space",
            "" to "Transaction",
            "   " to "Transaction",
            "Café ☕️" to "Café ☕️"
        )
        for ((title, expected) in cases) {
            assertEquals(expected, TransactionExportImage.sanitizedTitle(title))
        }
    }

    @Test
    fun capsTitleLength() {
        val title = "a".repeat(59) + " bcdef"

        assertEquals("a".repeat(59), TransactionExportImage.sanitizedTitle(title))
        assertEquals(60, TransactionExportImage.sanitizedTitle("b".repeat(80)).length)
    }

    @Test
    fun detectsJPEGAndPNG() {
        assertEquals("jpg", TransactionExportImage.fileExtension(jpeg))
        assertEquals("png", TransactionExportImage.fileExtension(png))
    }

    @Test
    fun detectsHEIC() {
        for (brand in listOf("heic", "heix", "mif1", "hevc")) {
            assertEquals("heic", TransactionExportImage.fileExtension(isoMedia(brand)))
        }
    }

    @Test
    fun fallsBackToJPEG() {
        assertEquals("jpg", TransactionExportImage.fileExtension(ByteArray(0)))
        assertEquals("jpg", TransactionExportImage.fileExtension(byteArrayOf(0x89.toByte(), 0x50)))
        assertEquals("jpg", TransactionExportImage.fileExtension("GIF89a".toByteArray()))
        assertEquals("jpg", TransactionExportImage.fileExtension(isoMedia("mp42")))
    }

    @Test
    fun fileName() {
        val date = calendar.date(2026, 10, 5, 23, 30)

        val fileName = TransactionExportImage.fileName(
            date = date,
            title = "Groceries / Market",
            transactionID = UUID.fromString("1A2B3C4D-0000-0000-0000-000000000001"),
            data = png,
            zone = PARIS
        )

        assertEquals("2026-10-05 Groceries - Market 1A2B3C4D.png", fileName)
        assertEquals("Images/2026-10-05 Groceries - Market 1A2B3C4D.png", TransactionExportImage.relativePath(fileName))
    }
}

class ExportSelectionTests {
    private val october = ExportMonthOption(UUID.randomUUID(), "October", Instant.now(), 4)
    private val september = ExportMonthOption(UUID.randomUUID(), "September", Instant.now(), 7)

    private fun selection(excluding: Set<UUID> = emptySet(), imagesIn: Set<UUID> = emptySet()) = ExportSelection(
        options = listOf(october, september),
        excludedMonthIDs = excluding,
        monthIDsWithImages = imagesIn,
        format = TransactionCSVFormat()
    )

    @Test
    fun everyMonthSelectedByDefault() {
        val selection = selection()

        assertTrue(selection.includesEveryMonth)
        assertEquals(11, selection.transactionCount)
        assertEquals(listOf(october.id, september.id), selection.file.monthIDs)
    }

    @Test
    fun excludedMonthsAreLeftOut() {
        val selection = selection(excluding = setOf(september.id))

        assertFalse(selection.includesEveryMonth)
        assertEquals(listOf(october), selection.selectedOptions)
        assertEquals(4, selection.transactionCount)
        assertEquals(listOf(october.id), selection.file.monthIDs)
    }

    @Test
    fun imagesFollowTheSelectedMonths() {
        assertTrue(selection(imagesIn = setOf(september.id)).file.hasImages)
        assertFalse(selection(excluding = setOf(september.id), imagesIn = setOf(september.id)).file.hasImages)
    }
}

class ExportMonthOptionTests {
    private val calendar = parisCalendar()

    private fun option(year: Int, month: Int) = ExportMonthOption(UUID.randomUUID(), "$year-$month", calendar.date(year, month, 1), 0)

    @Test
    fun groupsByYearNewestFirst() {
        val options = listOf(option(2025, 11), option(2026, 2), option(2025, 12), option(2026, 1))

        val groups = ExportMonthOption.groupedByYear(options, calendar)

        assertEquals(listOf(2026, 2025), groups.map { it.year })
        assertEquals(listOf(listOf("2026-2", "2026-1"), listOf("2025-12", "2025-11")), groups.map { group -> group.options.map { it.name } })
    }

    @Test
    fun emptyGivesNoGroups() {
        assertTrue(ExportMonthOption.groupedByYear(emptyList(), calendar).isEmpty())
    }
}
