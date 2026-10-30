package app.trente.core.model

import java.util.Locale

data class Currency(
    val isoCode: String,
    val symbol: String,
    val localizedName: String
) {
    val id: String get() = isoCode

    /** The system's name for the currency in the user's language, capitalized; the stored English name otherwise. */
    val displayName: String
        get() {
            val systemName = try {
                java.util.Currency.getInstance(isoCode).getDisplayName(Locale.getDefault())
            } catch (exception: IllegalArgumentException) {
                null
            } ?: return localizedName
            return systemName.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
        }

    companion object {
        val fallback = Currency(isoCode = "EUR", symbol = "€", localizedName = "Euro")
    }
}

object Currencies {
    val availableCurrencies: List<Currency> = listOf(
        Currency("USD", "$", "US Dollar"),
        Currency("EUR", "€", "Euro"),
        Currency("JPY", "¥", "Japanese Yen"),
        Currency("GBP", "£", "Pound Sterling"),
        Currency("CNY", "¥", "Chinese Yuan"),
        Currency("AUD", "A$", "Australian Dollar"),
        Currency("CAD", "C$", "Canadian Dollar"),
        Currency("CHF", "CHF", "Swiss Franc"),
        Currency("HKD", "HK$", "Hong Kong Dollar"),
        Currency("SGD", "S$", "Singapore Dollar"),
        Currency("SEK", "kr", "Swedish Krona"),
        Currency("KRW", "₩", "South Korean Won"),
        Currency("NOK", "kr", "Norwegian Krone"),
        Currency("NZD", "NZ$", "New Zealand Dollar"),
        Currency("INR", "₹", "Indian Rupee"),
        Currency("MXN", "MX$", "Mexican Peso"),
        Currency("TWD", "NT$", "New Taiwan Dollar"),
        Currency("ZAR", "R", "South African Rand"),
        Currency("BRL", "R$", "Brazilian Real"),
        Currency("DKK", "kr", "Danish Krone")
    )

    fun currency(isoCode: String): Currency? = availableCurrencies.firstOrNull { it.isoCode == isoCode }
}
