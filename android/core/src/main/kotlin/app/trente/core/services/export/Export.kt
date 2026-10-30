package app.trente.core.services.export

import app.trente.core.model.BudgetCategory
import app.trente.core.model.Month
import app.trente.core.model.TransactionEntry
import app.trente.core.model.TransactionGroup
import app.trente.core.model.TransactionType
import app.trente.core.model.TrenteCalendar
import app.trente.core.model.TrenteStore
import app.trente.core.support.TextSearch
import app.trente.core.support.localized
import java.io.File
import java.text.DecimalFormatSymbols
import java.time.Instant
import java.time.ZoneId
import java.util.Locale
import java.util.UUID
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

data class TransactionCSVFormat(
    val style: Style = Style.STANDARD,
    val includesNotes: Boolean = true,
    val includesImages: Boolean = true
) {
    enum class Style {
        STANDARD,
        EUROPEAN;

        companion object {
            val current: Style get() = of(Locale.getDefault())

            fun of(locale: Locale): Style =
                if (DecimalFormatSymbols.getInstance(locale).decimalSeparator == ',') EUROPEAN else STANDARD
        }
    }

    val separator: String get() = if (style == Style.STANDARD) "," else ";"

    val decimalSeparator: String get() = if (style == Style.STANDARD) "." else ","

    companion object {
        const val INCLUDES_NOTES_KEY = "export.includesNotes"
        const val INCLUDES_IMAGES_KEY = "export.includesImages"
    }
}

data class TransactionExportRow(
    val date: Instant,
    val monthStartDate: Instant,
    val title: String,
    val type: TransactionType,
    val category: BudgetCategory,
    val amountCents: Int,
    val currencyCode: String,
    val isRecurring: Boolean,
    val note: String?,
    val transactionID: UUID,
    val imageSourceID: UUID? = null
) {
    companion object {
        fun from(entry: TransactionEntry, group: TransactionGroup, month: Month, hasImage: Boolean = false) = TransactionExportRow(
            date = group.addedDate,
            monthStartDate = month.startDate,
            title = group.title,
            type = group.type,
            category = entry.category,
            amountCents = entry.amountCents,
            currencyCode = month.currency.isoCode,
            isRecurring = group.recurringOccurrenceDate != null,
            note = group.note,
            transactionID = group.id,
            imageSourceID = if (hasImage) group.id else null
        )

        fun rows(months: List<Month>, groupsWithImages: Set<UUID> = emptySet()): List<TransactionExportRow> =
            months.flatMap { month ->
                month.transactionGroups.flatMap { group ->
                    val hasImage = group.id in groupsWithImages
                    group.entries.map { entry -> from(entry, group, month, hasImage) }
                }
            }

        fun groupsWithImages(store: TrenteStore): Set<UUID> =
            store.transactionGroups.filter { it.hasImageAttachment }.map { it.id }.toSet()
    }
}

object TransactionCSVBuilder {
    val header = listOf("Date", "Month", "Title", "Type", "Category", "Amount", "Currency", "Recurring", "Note", "Transaction ID")

    private const val LINE_ENDING = "\r\n"
    private val charactersRequiringQuotes = setOf('"', '\r', '\n')
    private val formulaTriggers = setOf('=', '+', '-', '@', '\t', '\r')
    private const val IMAGE_COLUMN = "Image"

    fun header(format: TransactionCSVFormat, includesImages: Boolean = false): List<String> {
        val columns = (if (format.includesNotes) header else header.filter { it != "Note" }).toMutableList()
        if (includesImages) {
            columns.add(columns.size - 1, IMAGE_COLUMN)
        }
        return columns
    }

    fun csv(
        rows: List<TransactionExportRow>,
        format: TransactionCSVFormat = TransactionCSVFormat(),
        imagePaths: Map<UUID, String>? = null,
        zone: ZoneId = ZoneId.systemDefault()
    ): String {
        val records = listOf(header(format, includesImages = imagePaths != null)) +
            sorted(rows).map { fields(it, format, imagePaths, zone) }
        return records.joinToString("") { record ->
            record.joinToString(format.separator) { escaped(it, format.separator) } + LINE_ENDING
        }
    }

    fun monthText(date: Instant, zone: ZoneId = ZoneId.systemDefault()): String {
        val day = date.atZone(zone).toLocalDate()
        return String.format("%04d-%02d", day.year, day.monthValue)
    }

    fun dayText(date: Instant, zone: ZoneId = ZoneId.systemDefault()): String {
        val day = date.atZone(zone).toLocalDate()
        return String.format("%04d-%02d-%02d", day.year, day.monthValue, day.dayOfMonth)
    }

    fun amountText(cents: Long, decimalSeparator: String = "."): String {
        val sign = if (cents < 0) "-" else ""
        val magnitude = if (cents < 0) cents.toULong().inv() + 1u else cents.toULong()
        val units = magnitude / 100u
        val fraction = magnitude % 100u
        val fractionText = if (fraction < 10u) "0$fraction" else "$fraction"
        return "$sign$units$decimalSeparator$fractionText"
    }

    fun amountText(cents: Int, decimalSeparator: String = "."): String = amountText(cents.toLong(), decimalSeparator)

    fun escaped(field: String, separator: String = ","): String {
        val needsQuotes = field.contains(separator) || field.any { it in charactersRequiringQuotes }
        if (!needsQuotes) return field
        return "\"" + field.replace("\"", "\"\"") + "\""
    }

    /** Keeps a spreadsheet from running a title or a note as a formula. */
    fun neutralized(text: String): String {
        val first = text.firstOrNull() ?: return text
        return if (first in formulaTriggers) "'$text" else text
    }

    private fun sorted(rows: List<TransactionExportRow>): List<TransactionExportRow> =
        rows.sortedWith { lhs, rhs ->
            if (lhs.date != rhs.date) return@sortedWith lhs.date.compareTo(rhs.date)
            val titleOrder = TextSearch.compare(lhs.title, rhs.title)
            if (titleOrder != 0) return@sortedWith titleOrder
            if (lhs.transactionID != rhs.transactionID) {
                return@sortedWith lhs.transactionID.toString().uppercase().compareTo(rhs.transactionID.toString().uppercase())
            }
            lhs.category.ordinal.compareTo(rhs.category.ordinal)
        }

    private fun fields(row: TransactionExportRow, format: TransactionCSVFormat, imagePaths: Map<UUID, String>?, zone: ZoneId): List<String> {
        val fields = mutableListOf(
            dayText(row.date, zone),
            monthText(row.monthStartDate, zone),
            neutralized(row.title),
            row.type.rawValue,
            row.category.exportName,
            amountText(row.amountCents, format.decimalSeparator),
            row.currencyCode,
            if (row.isRecurring) "yes" else ""
        )
        if (format.includesNotes) {
            fields.add(neutralized(row.note ?: ""))
        }
        if (imagePaths != null) {
            fields.add(imagePaths[row.transactionID] ?: "")
        }
        fields.add(row.transactionID.toString().uppercase())
        return fields
    }

    private val BudgetCategory.exportName: String
        get() = when (this) {
            BudgetCategory.NEEDS -> "Needs"
            BudgetCategory.WANTS -> "Wants"
            BudgetCategory.SAVINGS_AND_DEBTS -> "Savings and Debts"
        }
}

object TransactionExportImage {
    const val FOLDER_NAME = "Images"

    private const val MAXIMUM_TITLE_LENGTH = 60
    private const val FALLBACK_TITLE = "Transaction"
    private val forbiddenCharacters = setOf('/', '\\', ':', '*', '?', '"', '<', '>', '|', '\n', '\r', '\u0085', ' ', ' ')
    private val heicBrands = setOf("ftypheic", "ftypheix", "ftypmif1", "ftyphevc")

    fun fileName(
        date: Instant,
        title: String,
        transactionID: UUID,
        data: ByteArray,
        zone: ZoneId = ZoneId.systemDefault()
    ): String {
        val day = TransactionCSVBuilder.dayText(date, zone)
        val shortID = transactionID.toString().uppercase().take(8)
        return "$day ${sanitizedTitle(title)} $shortID.${fileExtension(data)}"
    }

    fun relativePath(fileName: String): String = "$FOLDER_NAME/$fileName"

    fun sanitizedTitle(title: String): String {
        val collapsed = title
            .split { it in forbiddenCharacters }
            .joinToString("-")
            .split(Regex("\\s+"))
            .filter { it.isNotEmpty() }
            .joinToString(" ")
        val capped = collapsed.take(MAXIMUM_TITLE_LENGTH).trim(' ')
        return capped.ifEmpty { FALLBACK_TITLE }
    }

    private fun String.split(isSeparator: (Char) -> Boolean): List<String> {
        val parts = mutableListOf<String>()
        val current = StringBuilder()
        for (character in this) {
            if (isSeparator(character)) {
                parts.add(current.toString())
                current.clear()
            } else {
                current.append(character)
            }
        }
        parts.add(current.toString())
        return parts
    }

    fun fileExtension(data: ByteArray): String {
        val bytes = data.take(12)
        if (bytes.size >= 3 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xD8.toByte() && bytes[2] == 0xFF.toByte()) {
            return "jpg"
        }
        if (bytes.size >= 4 && bytes[0] == 0x89.toByte() && bytes[1] == 0x50.toByte() && bytes[2] == 0x4E.toByte() && bytes[3] == 0x47.toByte()) {
            return "png"
        }
        if (bytes.size == 12 && String(bytes.drop(4).toByteArray(), Charsets.ISO_8859_1) in heicBrands) {
            return "heic"
        }
        return "jpg"
    }

    fun rowsWithImages(rows: List<TransactionExportRow>): List<TransactionExportRow> {
        val seen = mutableSetOf<UUID>()
        return rows.filter { it.imageSourceID != null && seen.add(it.transactionID) }
    }

    /** Writes one file per transaction image and skips images removed since; returns the relative path of each. */
    fun writeImages(
        rows: List<TransactionExportRow>,
        folder: File,
        zone: ZoneId = ZoneId.systemDefault(),
        imageData: (UUID) -> ByteArray?
    ): Map<UUID, String> {
        val paths = mutableMapOf<UUID, String>()
        for (row in rowsWithImages(rows)) {
            val data = row.imageSourceID?.let(imageData) ?: continue
            val imageFileName = fileName(row.date, row.title, row.transactionID, data, zone)
            File(folder, imageFileName).writeBytes(data)
            paths[row.transactionID] = relativePath(imageFileName)
        }
        return paths
    }
}

data class TransactionsCSVFile(
    val monthIDs: List<UUID>,
    val fileName: String,
    val format: TransactionCSVFormat = TransactionCSVFormat(),
    val hasImages: Boolean = false
) {
    val includesImages: Boolean get() = format.includesImages && hasImages

    val csvFileName: String get() = "$fileName.csv"

    /** Writes the export under `exportsDirectory`, removing the previous export first: a zip with images, else a CSV. */
    fun write(store: TrenteStore, exportsDirectory: File): File {
        val rows = rows(store)
        val imageData: (UUID) -> ByteArray? = { id -> store.transactionGroup(id)?.imageAttachmentData }
        return if (includesImages) archive(rows, imageData, exportsDirectory) else writeCSV(rows, exportsDirectory)
    }

    fun csvData(rows: List<TransactionExportRow>, imagePaths: Map<UUID, String>? = null): ByteArray =
        BYTE_ORDER_MARK + TransactionCSVBuilder.csv(rows, format, imagePaths).toByteArray(Charsets.UTF_8)

    fun rows(store: TrenteStore): List<TransactionExportRow> {
        val months = store.months.filter { it.id in monthIDs }
        return TransactionExportRow.rows(months, TransactionExportRow.groupsWithImages(store))
    }

    fun writeFolder(rows: List<TransactionExportRow>, directory: File, imageData: (UUID) -> ByteArray?): File {
        val folder = File(directory, fileName)
        val imagesFolder = File(folder, TransactionExportImage.FOLDER_NAME)
        imagesFolder.mkdirs()
        val imagePaths = TransactionExportImage.writeImages(rows, imagesFolder, imageData = imageData)
        File(folder, csvFileName).writeBytes(csvData(rows, imagePaths))
        return folder
    }

    fun archive(rows: List<TransactionExportRow>, imageData: (UUID) -> ByteArray?, exportsDirectory: File): File {
        val directory = makeTemporaryDirectory(exportsDirectory)
        try {
            val folder = writeFolder(rows, directory, imageData)
            val archive = File(directory, "$fileName.zip")
            zip(folder, archive)
            folder.deleteRecursively()
            return archive
        } catch (exception: Exception) {
            directory.deleteRecursively()
            throw exception
        }
    }

    fun writeCSV(rows: List<TransactionExportRow>, exportsDirectory: File): File {
        val directory = makeTemporaryDirectory(exportsDirectory)
        try {
            val file = File(directory, csvFileName)
            file.writeBytes(csvData(rows))
            return file
        } catch (exception: Exception) {
            directory.deleteRecursively()
            throw exception
        }
    }

    private fun makeTemporaryDirectory(exportsDirectory: File): File {
        exportsDirectory.deleteRecursively()
        val directory = File(exportsDirectory, UUID.randomUUID().toString())
        directory.mkdirs()
        return directory
    }

    private fun zip(folder: File, destination: File) {
        ZipOutputStream(destination.outputStream().buffered()).use { zip ->
            folder.walkTopDown().filter { it.isFile }.forEach { file ->
                val relativePath = folder.name + "/" + file.relativeTo(folder).path.replace(File.separatorChar, '/')
                zip.putNextEntry(ZipEntry(relativePath))
                file.inputStream().use { it.copyTo(zip) }
                zip.closeEntry()
            }
        }
    }

    companion object {
        private val BYTE_ORDER_MARK = byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte())

        val allMonthsFileName: String get() = localized("Trente All Months")

        fun fileName(month: Month): String = "Trente ${TransactionCSVBuilder.monthText(month.startDate)}"

        fun fileName(startDates: List<Instant>, includesEveryMonth: Boolean, zone: ZoneId = ZoneId.systemDefault()): String {
            if (includesEveryMonth) return allMonthsFileName
            val first = startDates.minOrNull() ?: return allMonthsFileName
            val last = startDates.maxOrNull() ?: return allMonthsFileName
            val firstText = TransactionCSVBuilder.monthText(first, zone)
            val lastText = TransactionCSVBuilder.monthText(last, zone)
            return if (firstText == lastText) "Trente $firstText" else "Trente $firstText – $lastText"
        }
    }
}

data class ExportMonthOption(
    val id: UUID,
    val name: String,
    val startDate: Instant,
    val transactionCount: Int
) {
    data class YearGroup(val year: Int, val options: List<ExportMonthOption>) {
        val id: Int get() = year
    }

    companion object {
        fun from(month: Month) = ExportMonthOption(month.id, month.name, month.startDate, month.transactionGroups.size)

        fun groupedByYear(options: List<ExportMonthOption>, calendar: TrenteCalendar = TrenteCalendar.current): List<YearGroup> {
            val byYear = options.groupBy { calendar.localDate(it.startDate).year }
            return byYear.keys.sortedDescending().map { year ->
                YearGroup(year, byYear.getValue(year).sortedByDescending { it.startDate })
            }
        }
    }
}

data class ExportSelection(
    val options: List<ExportMonthOption>,
    val excludedMonthIDs: Set<UUID>,
    val monthIDsWithImages: Set<UUID>,
    val format: TransactionCSVFormat
) {
    val selectedOptions: List<ExportMonthOption> get() = options.filter { it.id !in excludedMonthIDs }

    val includesEveryMonth: Boolean get() = excludedMonthIDs.isEmpty()

    val transactionCount: Int get() = selectedOptions.sumOf { it.transactionCount }

    val file: TransactionsCSVFile
        get() {
            val selected = selectedOptions
            return TransactionsCSVFile(
                monthIDs = selected.map { it.id },
                fileName = TransactionsCSVFile.fileName(selected.map { it.startDate }, includesEveryMonth),
                format = format,
                hasImages = selected.any { it.id in monthIDsWithImages }
            )
        }
}
