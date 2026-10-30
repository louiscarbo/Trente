package app.trente.ui.theme

import android.graphics.Color as AndroidColor
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.trente.core.model.BudgetCategory
import app.trente.core.model.BudgetScope

/** Spacing and radius tokens, the same as the iOS `DesignSystem`. */
object Dimens {
    val radiusLarge = 26.dp
    val spacingSmall = 8.dp
    val spacingMedium = 12.dp
    val spacingLarge = 18.dp
    val cardBorder = 3.dp
}

val CardShape = RoundedCornerShape(Dimens.radiusLarge)

/** Trente's palette: the system colors of iOS, in their light and dark variants. */
object TrenteColors {
    val blue: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFF0A84FF) else Color(0xFF007AFF)
    val yellow: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFFFFD60A) else Color(0xFFFFCC00)
    val green: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFF30D158) else Color(0xFF34C759)
    val red: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFFFF453A) else Color(0xFFFF3B30)
    val orange: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFFFF9F0A) else Color(0xFFFF9500)
    val purple: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFFBF5AF2) else Color(0xFFAF52DE)
    val pink: Color @Composable @ReadOnlyComposable get() = if (isSystemInDarkTheme()) Color(0xFFFF375F) else Color(0xFFFF2D55)
    val gray: Color @Composable @ReadOnlyComposable get() = Color(0xFF8E8E93)

    val secondaryText: Color @Composable @ReadOnlyComposable get() = MaterialTheme.colorScheme.onSurfaceVariant
    val primaryText: Color @Composable @ReadOnlyComposable get() = MaterialTheme.colorScheme.onSurface
}

val BudgetCategory.color: Color
    @Composable @ReadOnlyComposable get() = when (this) {
        BudgetCategory.NEEDS -> TrenteColors.blue
        BudgetCategory.WANTS -> TrenteColors.yellow
        BudgetCategory.SAVINGS_AND_DEBTS -> TrenteColors.green
    }

val BudgetScope.color: Color
    @Composable @ReadOnlyComposable get() = when (this) {
        BudgetScope.All -> TrenteColors.purple
        is BudgetScope.Category -> category.color
    }

/** Lowers brightness and raises saturation by `amount`, like the iOS `darken(_:)`. Negative amounts lighten. */
fun Color.darken(amount: Float): Color = adjusted(brightnessDrop = amount, saturationBoost = amount)

fun Color.lighten(amount: Float): Color = adjusted(brightnessDrop = -amount, saturationBoost = -amount)

fun Color.adjusted(brightnessDrop: Float, saturationBoost: Float): Color {
    val hsv = FloatArray(3)
    AndroidColor.colorToHSV(toArgb(), hsv)
    hsv[1] = (hsv[1] + saturationBoost).coerceIn(0f, 1f)
    hsv[2] = (hsv[2] - brightnessDrop).coerceIn(0f, 1f)
    return Color(AndroidColor.HSVToColor((alpha * 255).toInt(), hsv))
}

private val lightScheme: ColorScheme = lightColorScheme(
    primary = Color(0xFF007AFF),
    onPrimary = Color.White,
    secondary = Color(0xFFFF2D55),
    tertiary = Color(0xFF34C759),
    error = Color(0xFFFF3B30),
    background = Color(0xFFF2F2F7),
    onBackground = Color(0xFF000000),
    surface = Color(0xFFF2F2F7),
    onSurface = Color(0xFF000000),
    surfaceVariant = Color(0xFFE5E5EA),
    onSurfaceVariant = Color(0xFF6C6C70),
    surfaceContainer = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF7F7FA),
    surfaceContainerHigh = Color(0xFFFFFFFF),
    surfaceContainerHighest = Color(0xFFFFFFFF),
    outline = Color(0xFFC6C6C8),
    outlineVariant = Color(0xFFE5E5EA)
)

private val darkScheme: ColorScheme = darkColorScheme(
    primary = Color(0xFF0A84FF),
    onPrimary = Color.White,
    secondary = Color(0xFFFF375F),
    tertiary = Color(0xFF30D158),
    error = Color(0xFFFF453A),
    background = Color(0xFF000000),
    onBackground = Color(0xFFFFFFFF),
    surface = Color(0xFF000000),
    onSurface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFF2C2C2E),
    onSurfaceVariant = Color(0xFF8E8E93),
    surfaceContainer = Color(0xFF1C1C1E),
    surfaceContainerLow = Color(0xFF121214),
    surfaceContainerHigh = Color(0xFF2C2C2E),
    surfaceContainerHighest = Color(0xFF3A3A3C),
    outline = Color(0xFF48484A),
    outlineVariant = Color(0xFF2C2C2E)
)

/** iOS text styles, so screens read like their SwiftUI originals. */
object TrenteType {
    val largeTitle = TextStyle(fontSize = 34.sp, lineHeight = 41.sp, fontWeight = FontWeight.Bold)
    val title = TextStyle(fontSize = 28.sp, lineHeight = 34.sp, fontWeight = FontWeight.Bold)
    val title2 = TextStyle(fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.Bold)
    val title3 = TextStyle(fontSize = 20.sp, lineHeight = 25.sp, fontWeight = FontWeight.SemiBold)
    val headline = TextStyle(fontSize = 17.sp, lineHeight = 22.sp, fontWeight = FontWeight.SemiBold)
    val body = TextStyle(fontSize = 17.sp, lineHeight = 22.sp)
    val subheadline = TextStyle(fontSize = 15.sp, lineHeight = 20.sp)
    val footnote = TextStyle(fontSize = 13.sp, lineHeight = 18.sp)
    val caption = TextStyle(fontSize = 12.sp, lineHeight = 16.sp)
    val caption2 = TextStyle(fontSize = 11.sp, lineHeight = 13.sp)
}

private val typography = Typography(
    headlineLarge = TrenteType.largeTitle,
    headlineMedium = TrenteType.title,
    headlineSmall = TrenteType.title2,
    titleLarge = TrenteType.title3,
    titleMedium = TrenteType.headline,
    titleSmall = TrenteType.subheadline.copy(fontWeight = FontWeight.SemiBold),
    bodyLarge = TrenteType.body,
    bodyMedium = TrenteType.subheadline,
    bodySmall = TrenteType.footnote,
    labelLarge = TrenteType.headline,
    labelMedium = TrenteType.caption,
    labelSmall = TrenteType.caption2
)

@Composable
fun TrenteTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) darkScheme else lightScheme,
        typography = typography,
        content = content
    )
}
