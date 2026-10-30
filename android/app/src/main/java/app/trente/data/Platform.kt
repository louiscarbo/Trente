package app.trente.data

import android.content.Context
import android.content.SharedPreferences
import android.icu.number.NumberFormatter
import android.icu.number.Precision
import android.icu.text.DecimalFormat
import android.icu.text.NumberFormat
import android.icu.util.Currency
import android.os.Build
import android.text.format.DateFormat
import app.trente.core.support.DateTextProvider
import app.trente.core.support.DefaultLocalizedStringProvider
import app.trente.core.support.KeyValueStore
import app.trente.core.support.LocalizedStringProvider
import app.trente.core.support.MoneyFormatter
import app.trente.l10n.StringKeys
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/** `UserDefaults.standard`, as SharedPreferences. */
class PreferencesStore(context: Context, name: String = "trente") : KeyValueStore {
    private val preferences: SharedPreferences = context.applicationContext.getSharedPreferences(name, Context.MODE_PRIVATE)

    fun registerListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) = preferences.registerOnSharedPreferenceChangeListener(listener)
    fun unregisterListener(listener: SharedPreferences.OnSharedPreferenceChangeListener) = preferences.unregisterOnSharedPreferenceChangeListener(listener)

    override fun getString(key: String): String? = preferences.getString(key, null)
    override fun putString(key: String, value: String) = preferences.edit().putString(key, value).apply()
    override fun getInt(key: String): Int? = if (preferences.contains(key)) preferences.getInt(key, 0) else null
    override fun putInt(key: String, value: Int) = preferences.edit().putInt(key, value).apply()
    override fun getLong(key: String): Long? = if (preferences.contains(key)) preferences.getLong(key, 0) else null
    override fun putLong(key: String, value: Long) = preferences.edit().putLong(key, value).apply()
    override fun getBoolean(key: String): Boolean? = if (preferences.contains(key)) preferences.getBoolean(key, false) else null
    override fun putBoolean(key: String, value: Boolean) = preferences.edit().putBoolean(key, value).apply()
    override fun getDouble(key: String): Double? = if (preferences.contains(key)) Double.fromBits(preferences.getLong(key, 0)) else null
    override fun putDouble(key: String, value: Double) = preferences.edit().putLong(key, value.toBits()).apply()
    override fun remove(key: String) = preferences.edit().remove(key).apply()
}

/** Resolves the English keys of the core module through the generated string resources. */
class AndroidStrings(private val context: Context) : LocalizedStringProvider {
    override fun localized(key: String, args: Array<out Any?>): String {
        val id = StringKeys.ids[key] ?: return DefaultLocalizedStringProvider.localized(key, args)
        return if (args.isEmpty()) context.getString(id) else context.getString(id, *args)
    }

    fun plural(key: String, count: Int, vararg args: Any?): String {
        val id = StringKeys.pluralIds[key] ?: return DefaultLocalizedStringProvider.localized(key, if (args.isEmpty()) arrayOf(count) else args)
        return context.resources.getQuantityString(id, count, *(if (args.isEmpty()) arrayOf(count) else args))
    }
}

/** Date text from ICU's localized skeletons, like Foundation's `formatted(.dateTime...)`. */
class AndroidDateText : DateTextProvider {
    private fun format(skeleton: String, date: LocalDate): String {
        val locale = Locale.getDefault()
        val pattern = DateFormat.getBestDateTimePattern(locale, skeleton)
        return DateTimeFormatter.ofPattern(pattern, locale).format(date)
    }

    override fun monthYear(date: LocalDate) = format("yMMMM", date)
    override fun monthWide(date: LocalDate) = format("LLLL", date)
    override fun dayMonthWide(date: LocalDate) = format("dMMMM", date)
    override fun weekdayWide(date: LocalDate) = format("EEEE", date)
    override fun monthWideDay(date: LocalDate) = format("MMMMd", date)
    override fun fullDate(date: LocalDate) = format("EEEEdMMMMy", date)
    override fun mediumDate(date: LocalDate) = format("yMMMd", date)
}

/** Money text with the narrow currency symbol ("$" rather than "US$"). */
class AndroidMoney : MoneyFormatter {
    private fun format(value: Double, currencyCode: String, fractionDigits: Int): String {
        val locale = Locale.getDefault()
        val currency = try {
            Currency.getInstance(currencyCode)
        } catch (exception: IllegalArgumentException) {
            null
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && currency != null) {
            return NumberFormatter.withLocale(locale)
                .unit(currency)
                .unitWidth(NumberFormatter.UnitWidth.NARROW)
                .precision(Precision.fixedFraction(fractionDigits))
                .format(value)
                .toString()
        }
        val format = NumberFormat.getCurrencyInstance(locale)
        if (currency != null) {
            format.currency = currency
            (format as? DecimalFormat)?.let { decimal ->
                val symbols = decimal.decimalFormatSymbols
                symbols.currencySymbol = currency.getName(locale, Currency.NARROW_SYMBOL_NAME, null)
                decimal.decimalFormatSymbols = symbols
            }
        }
        format.minimumFractionDigits = fractionDigits
        format.maximumFractionDigits = fractionDigits
        return format.format(value)
    }

    override fun amount(value: Double, currencyCode: String) = format(value, currencyCode, 2)
    override fun budget(value: Double, currencyCode: String) = format(value, currencyCode, 0)
}
