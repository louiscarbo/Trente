package app.trente.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.theme.TrenteColors
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs

/**
 * An amount in the user's decimal format, stored in cents. The sign of the current value is kept:
 * typing into a negative amount keeps it negative, like the iOS `CurrencyTextField`.
 */
@Composable
fun CurrencyTextField(
    amountCents: Int,
    onAmountChange: (Int) -> Unit,
    currencyCode: String,
    modifier: Modifier = Modifier,
    textStyle: TextStyle = MaterialTheme.typography.headlineMedium,
    textAlign: TextAlign = TextAlign.Center,
    enabled: Boolean = true,
    focusRequester: FocusRequester? = null
) {
    val separator = remember { DecimalFormatSymbols.getInstance(Locale.getDefault()).decimalSeparator }
    var field by remember { mutableStateOf(endOfText(formatCents(amountCents, separator))) }

    LaunchedEffect(amountCents) {
        val text = field.text
        field = when {
            parseCents(text, separator) != abs(amountCents) -> endOfText(formatCents(amountCents, separator))
            amountCents == 0 && text == "-" -> endOfText("")
            amountCents < 0 && !text.startsWith("-") -> field.withSignOffset("-$text", 1)
            amountCents > 0 && text.startsWith("-") -> field.withSignOffset(text.removePrefix("-"), -1)
            else -> field
        }
    }

    val color = LocalContentColor.current
    Box(modifier, contentAlignment = Alignment.Center) {
        if (field.text.isEmpty()) {
            Text(
                MoneyFormat.amount(0.0, currencyCode),
                style = textStyle,
                color = TrenteColors.secondaryText.copy(alpha = 0.5f),
                textAlign = textAlign,
                modifier = Modifier.fillMaxWidthIf(textAlign == TextAlign.Center)
            )
        }
        BasicTextField(
            value = field,
            onValueChange = { newField ->
                val newText = newField.text
                if (!isAcceptable(newText, separator)) return@BasicTextField
                val hasNewText = newText != field.text
                field = newField
                if (hasNewText) {
                    val cents = parseCents(newText, separator)
                    onAmountChange(if (amountCents < 0 || newText.startsWith("-")) -cents else cents)
                }
            },
            enabled = enabled,
            singleLine = true,
            textStyle = textStyle.copy(color = color, textAlign = textAlign),
            cursorBrush = SolidColor(color),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal, imeAction = ImeAction.Done),
            modifier = Modifier
                .fillMaxWidthIf(textAlign == TextAlign.Center)
                .let { if (focusRequester != null) it.focusRequester(focusRequester) else it }
                .semantics { contentDescription = localized("Amount") }
        )
    }
}

private fun Modifier.fillMaxWidthIf(condition: Boolean): Modifier = if (condition) this.fillMaxWidth() else this

private fun endOfText(text: String) = TextFieldValue(text, TextRange(text.length))

private fun TextFieldValue.withSignOffset(text: String, offset: Int) =
    TextFieldValue(text, TextRange((selection.start + offset).coerceIn(0, text.length), (selection.end + offset).coerceIn(0, text.length)))

private fun isAcceptable(text: String, separator: Char): Boolean {
    val body = text.removePrefix("-")
    if (body.any { !it.isDigit() && it != separator && it != '.' && it != ',' }) return false
    val separators = body.count { it == separator || it == '.' || it == ',' }
    if (separators > 1) return false
    val decimals = body.substringAfter(separator, body.substringAfter('.', body.substringAfter(',', "")))
    return separators == 0 || decimals.length <= 2
}

private fun parseCents(text: String, separator: Char): Int {
    val normalized = text.removePrefix("-").replace(separator, '.').replace(',', '.')
    if (normalized.isEmpty()) return 0
    val parts = normalized.split('.', limit = 2)
    val units = parts[0].toLongOrNull() ?: 0L
    val fraction = parts.getOrNull(1)?.padEnd(2, '0')?.take(2)?.toLongOrNull() ?: 0L
    return (units * 100 + fraction).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
}

private fun formatCents(cents: Int, separator: Char): String {
    if (cents == 0) return ""
    val magnitude = abs(cents)
    val units = magnitude / 100
    val fraction = magnitude % 100
    val fractionText = if (fraction == 0) "" else "$separator${fraction.toString().padStart(2, '0')}"
    return (if (cents < 0) "-" else "") + units + fractionText
}
