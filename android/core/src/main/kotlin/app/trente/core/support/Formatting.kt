package app.trente.core.support

import java.text.NumberFormat
import java.text.Normalizer
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Localized date text. The app replaces the JVM provider with one using Android's ICU skeletons. */
interface DateTextProvider {
    /** "October 2026" */
    fun monthYear(date: LocalDate): String

    /** "October" */
    fun monthWide(date: LocalDate): String

    /** "5 October" */
    fun dayMonthWide(date: LocalDate): String

    /** "Monday" */
    fun weekdayWide(date: LocalDate): String

    /** "October 5" */
    fun monthWideDay(date: LocalDate): String

    /** "Monday, October 5, 2026" */
    fun fullDate(date: LocalDate): String

    /** "Oct 5, 2026" */
    fun mediumDate(date: LocalDate): String
}

object DateText : DateTextProvider {
    @Volatile
    var provider: DateTextProvider = JvmDateTextProvider

    override fun monthYear(date: LocalDate) = provider.monthYear(date)
    override fun monthWide(date: LocalDate) = provider.monthWide(date)
    override fun dayMonthWide(date: LocalDate) = provider.dayMonthWide(date)
    override fun weekdayWide(date: LocalDate) = provider.weekdayWide(date)
    override fun monthWideDay(date: LocalDate) = provider.monthWideDay(date)
    override fun fullDate(date: LocalDate) = provider.fullDate(date)
    override fun mediumDate(date: LocalDate) = provider.mediumDate(date)
}

object JvmDateTextProvider : DateTextProvider {
    private fun format(pattern: String, date: LocalDate): String =
        DateTimeFormatter.ofPattern(pattern, Locale.getDefault()).format(date)

    override fun monthYear(date: LocalDate) = format("LLLL yyyy", date)
    override fun monthWide(date: LocalDate) = format("LLLL", date)
    override fun dayMonthWide(date: LocalDate) = format("d MMMM", date)
    override fun weekdayWide(date: LocalDate) = format("EEEE", date)
    override fun monthWideDay(date: LocalDate) = format("MMMM d", date)
    override fun fullDate(date: LocalDate) = format("EEEE, MMMM d, yyyy", date)
    override fun mediumDate(date: LocalDate) = format("MMM d, yyyy", date)
}

/** Localized money text. */
interface MoneyFormatter {
    /** With cents: "€12.50" */
    fun amount(value: Double, currencyCode: String): String

    /** Without cents: "€2,000" */
    fun budget(value: Double, currencyCode: String): String
}

object MoneyFormat : MoneyFormatter {
    @Volatile
    var formatter: MoneyFormatter = JvmMoneyFormatter

    override fun amount(value: Double, currencyCode: String) = formatter.amount(value, currencyCode)
    override fun budget(value: Double, currencyCode: String) = formatter.budget(value, currencyCode)

    fun amountCents(cents: Int, currencyCode: String) = amount(cents / 100.0, currencyCode)
}

object JvmMoneyFormatter : MoneyFormatter {
    private fun format(value: Double, currencyCode: String, fractionDigits: Int): String {
        val format = NumberFormat.getCurrencyInstance(Locale.getDefault())
        try {
            format.currency = java.util.Currency.getInstance(currencyCode)
        } catch (exception: IllegalArgumentException) {
            // Keep the locale's currency symbol for an unknown code.
        }
        format.minimumFractionDigits = fractionDigits
        format.maximumFractionDigits = fractionDigits
        return format.format(value)
    }

    override fun amount(value: Double, currencyCode: String) = format(value, currencyCode, 2)
    override fun budget(value: Double, currencyCode: String) = format(value, currencyCode, 0)
}

/** Case- and accent-insensitive text matching, like Foundation's `localizedStandardContains`. */
object TextSearch {
    private val combiningMarks = Regex("\\p{M}+")

    fun normalized(text: String): String =
        combiningMarks.replace(Normalizer.normalize(text, Normalizer.Form.NFD), "").lowercase(Locale.getDefault())

    fun contains(text: String, query: String): Boolean = normalized(text).contains(normalized(query))

    /** Case-insensitive, digit runs compared by value, like `.caseInsensitive` + `.numeric`. */
    fun compare(lhs: String, rhs: String): Int {
        val left = lhs.lowercase(Locale.getDefault())
        val right = rhs.lowercase(Locale.getDefault())
        var i = 0
        var j = 0
        while (i < left.length && j < right.length) {
            if (left[i].isDigit() && right[j].isDigit()) {
                val startI = i
                val startJ = j
                while (i < left.length && left[i].isDigit()) i++
                while (j < right.length && right[j].isDigit()) j++
                val numberI = left.substring(startI, i).trimStart('0')
                val numberJ = right.substring(startJ, j).trimStart('0')
                val byLength = numberI.length.compareTo(numberJ.length)
                if (byLength != 0) return byLength
                val byValue = numberI.compareTo(numberJ)
                if (byValue != 0) return byValue
            } else {
                val byChar = left[i].compareTo(right[j])
                if (byChar != 0) return byChar
                i++
                j++
            }
        }
        return (left.length - i).compareTo(right.length - j)
    }
}
