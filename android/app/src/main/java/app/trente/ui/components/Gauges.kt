package app.trente.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.sp
import app.trente.ui.theme.adjusted
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetFigures
import app.trente.core.model.BudgetScope
import app.trente.core.presentation.BudgetRings
import app.trente.core.presentation.ProportionalLayout
import app.trente.core.support.MoneyFormat
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import app.trente.ui.theme.darken
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** A 270° ring gauge opening at the bottom, like `TrenteGaugeStyle`. */
@Composable
fun TrenteGauge(
    value: Float,
    color: Color,
    diameter: Dp,
    modifier: Modifier = Modifier,
    highlightsRemaining: Boolean = false,
    label: @Composable () -> Unit
) {
    val fraction = value.coerceIn(0f, 1f)
    Box(modifier.size(diameter), contentAlignment = Alignment.Center) {
        Canvas(Modifier.size(diameter)) {
            val strokeWidth = size.minDimension / 6
            val inset = strokeWidth / 2
            val arcSize = Size(size.width - strokeWidth, size.height - strokeWidth)
            val topLeft = Offset(inset, inset)
            val stroke = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            drawArc(color.copy(alpha = 0.3f), startAngle = 135f, sweepAngle = 270f, useCenter = false, topLeft = topLeft, size = arcSize, style = stroke)
            if (highlightsRemaining) {
                val start = 135f + 270f * fraction
                drawArc(color, startAngle = start, sweepAngle = 270f * (1 - fraction), useCenter = false, topLeft = topLeft, size = arcSize, style = stroke)
            } else if (fraction > 0f) {
                drawArc(color, startAngle = 135f, sweepAngle = 270f * fraction, useCenter = false, topLeft = topLeft, size = arcSize, style = stroke)
            }
            val angle = Math.toRadians((135f + 270f * fraction).toDouble())
            val radius = (size.minDimension - strokeWidth) / 2
            val center = Offset(size.width / 2 + radius * cos(angle).toFloat(), size.height / 2 + radius * sin(angle).toFloat())
            drawCircle(Color.White, radius = strokeWidth * 0.3f, center = center)
        }
        label()
    }
}

/** The gauge of one scope: spent over income, red when overspent, like `BudgetGaugeView`. */
@Composable
fun BudgetGaugeView(
    figures: BudgetFigures,
    scope: BudgetScope,
    currencyCode: String,
    size: Dp,
    modifier: Modifier = Modifier,
    showRemaining: Boolean = false,
    showsPercentage: Boolean = false
) {
    val isOverspent = figures.isOverspent
    val scopeColor = scope.color
    val color = when {
        showRemaining -> if (isOverspent) TrenteColors.red else scopeColor
        figures.spent == 0.0 -> TrenteColors.gray
        isOverspent -> TrenteColors.red
        else -> scopeColor
    }
    val value = when {
        figures.income <= 0 -> if (figures.spent > 0) 1f else 0f
        showRemaining && isOverspent -> 1f
        isOverspent -> ((-figures.remaining) % figures.income / figures.income).toFloat()
        else -> (figures.spent / figures.income).toFloat()
    }
    val displayed = if (showRemaining) figures.remaining else figures.spent
    val textColor = if (isOverspent) TrenteColors.red else MaterialTheme.colorScheme.onSurface
    TrenteGauge(value = value, color = color, diameter = size, modifier = modifier, highlightsRemaining = showRemaining) {
        if (showsPercentage && figures.income > 0) {
            Text("${(displayed / figures.income * 100).toInt()}%", style = TrenteType.headline, color = textColor)
        } else {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(MoneyFormat.budget(displayed, currencyCode), style = TrenteType.headline, color = textColor, maxLines = 1)
                HorizontalDivider(Modifier.width(size / 2))
                Text(MoneyFormat.budget(figures.income, currencyCode), style = TrenteType.footnote, color = TrenteColors.secondaryText, maxLines = 1)
            }
        }
    }
}

/** A horizontal bar whose slices follow their weights, like a horizontal `ProportionalStack`. */
@Composable
fun ProportionalBar(
    slices: List<Pair<Color, Double>>,
    modifier: Modifier = Modifier,
    height: Dp = 10.dp,
    spacing: Dp = 3.dp,
    minimumLength: Dp = 3.dp,
    cornerRadius: Dp = 3.dp
) {
    val density = LocalDensity.current
    Canvas(modifier.fillMaxWidth().height(height)) {
        val visible = slices.filter { it.second > 0 }
        if (visible.isEmpty()) return@Canvas
        val spacingPx = with(density) { spacing.toPx() }
        val available = size.width - spacingPx * (visible.size - 1)
        val lengths = ProportionalLayout.lengths(visible.map { it.second }, available.toDouble(), with(density) { minimumLength.toPx() }.toDouble())
        var x = 0f
        visible.forEachIndexed { index, (color, _) ->
            val width = lengths[index].toFloat()
            drawRoundRect(color, topLeft = Offset(x, 0f), size = Size(width, size.height), cornerRadius = androidx.compose.ui.geometry.CornerRadius(with(density) { cornerRadius.toPx() }))
            x += width + spacingPx
        }
    }
}

/** The donut of the dashboard: a thin plan ring outside, the spending segments inside, a share in the centre. */
@Composable
fun BudgetRingsView(
    segments: List<BudgetRings.Slice>,
    plan: List<BudgetRings.Slice>,
    centerShare: Double?,
    centerCaption: String,
    isOverspent: Boolean,
    showsCaptionAsAlert: Boolean,
    modifier: Modifier = Modifier
) {
    val categoryColors = app.trente.core.model.BudgetCategory.entries.associateWith { it.color }
    val gray = TrenteColors.gray
    val red = TrenteColors.red
    val onSurface = MaterialTheme.colorScheme.onSurface
    val secondary = TrenteColors.secondaryText
    val labelColor = onSurface.toArgb()
    fun fill(kind: BudgetRings.SliceKind, inPlan: Boolean): Color = when (kind) {
        is BudgetRings.SliceKind.Category -> categoryColors.getValue(kind.category).let { if (inPlan) it.adjustedForPlan() else it }
        BudgetRings.SliceKind.Remaining -> gray.copy(alpha = if (inPlan) 0.3f else 0.4f)
        BudgetRings.SliceKind.Overspent -> red.copy(alpha = if (inPlan) 0.5f else 1f)
    }
    Box(modifier.aspectRatio(1f), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxWidth().aspectRatio(1f)) {
            val outer = size.minDimension / 2
            val center = Offset(size.width / 2, size.height / 2)
            fun drawRing(slices: List<BudgetRings.Slice>, innerRatio: Float, outerRatio: Float, gapDegrees: Float, inPlan: Boolean) {
                val total = slices.sumOf { it.share }
                if (total <= 0) {
                    drawRingSector(center, outer * innerRatio, outer * outerRatio, -90f, 360f, gray.copy(alpha = 0.18f))
                    return
                }
                var start = -90f
                for (slice in slices) {
                    val sweep = (slice.share / total * 360).toFloat()
                    if (sweep <= 0f) continue
                    val gap = if (slices.count { it.share > 0 } > 1) min(gapDegrees, sweep / 2) else 0f
                    drawRingSector(center, outer * innerRatio, outer * outerRatio, start + gap / 2, sweep - gap, fill(slice.kind, inPlan))
                    start += sweep
                }
            }
            drawRing(plan, 0.945f, 1f, 1.5f, inPlan = true)
            drawRing(segments, 0.51f, 0.873f, 4f, inPlan = false)

            val total = segments.sumOf { it.share }
            if (total > 0) {
                var start = -90f
                val paint = android.graphics.Paint().apply {
                    isAntiAlias = true
                    textSize = 11.sp.toPx()
                    textAlign = android.graphics.Paint.Align.CENTER
                    typeface = android.graphics.Typeface.create(android.graphics.Typeface.MONOSPACE, android.graphics.Typeface.BOLD)
                }
                for (slice in segments) {
                    val sweep = (slice.share / total * 360).toFloat()
                    if (slice.share >= 0.072 && slice.share < 0.995) {
                        val angle = Math.toRadians((start + sweep / 2).toDouble())
                        val radius = outer * 0.69f
                        val kind = slice.kind
                        paint.color = when (kind) {
                            is BudgetRings.SliceKind.Category -> categoryColors.getValue(kind.category).darken(0.8f).toArgb()
                            BudgetRings.SliceKind.Overspent -> android.graphics.Color.WHITE
                            BudgetRings.SliceKind.Remaining -> labelColor
                        }
                        drawContext.canvas.nativeCanvas.drawText(
                            "${(slice.share * 100).toInt()}%",
                            center.x + radius * cos(angle).toFloat(),
                            center.y + radius * sin(angle).toFloat() + paint.textSize / 3,
                            paint
                        )
                    }
                    start += sweep
                }
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                centerShare?.let { "${(it * 100).toInt()}%" } ?: "–",
                style = TrenteType.title,
                color = if (isOverspent) red else onSurface
            )
            Text(
                centerCaption,
                style = TrenteType.footnote.copy(fontWeight = FontWeight.SemiBold),
                color = if (showsCaptionAsAlert) red else secondary
            )
        }
    }
}

private fun Color.adjustedForPlan(): Color = adjusted(brightnessDrop = -0.1f, saturationBoost = -0.2f)

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawRingSector(
    center: Offset,
    innerRadius: Float,
    outerRadius: Float,
    startAngle: Float,
    sweepAngle: Float,
    color: Color
) {
    val path = Path().apply {
        arcTo(
            rect = androidx.compose.ui.geometry.Rect(center - Offset(outerRadius, outerRadius), Size(outerRadius * 2, outerRadius * 2)),
            startAngleDegrees = startAngle,
            sweepAngleDegrees = sweepAngle,
            forceMoveTo = true
        )
        arcTo(
            rect = androidx.compose.ui.geometry.Rect(center - Offset(innerRadius, innerRadius), Size(innerRadius * 2, innerRadius * 2)),
            startAngleDegrees = startAngle + sweepAngle,
            sweepAngleDegrees = -sweepAngle,
            forceMoveTo = false
        )
        close()
    }
    drawPath(path, color)
}

/** Three category slices of equal height stacked by weight, a cheap stand-in for the onboarding treemap. */
@Composable
fun WeightedColumn(
    weights: List<Double>,
    modifier: Modifier = Modifier,
    spacing: Dp = 8.dp,
    content: @Composable (Int) -> Unit
) {
    Layout(
        content = { weights.indices.forEach { content(it) } },
        modifier = modifier
    ) { measurables, constraints ->
        val spacingPx = spacing.roundToPx()
        val available = max(constraints.maxHeight - spacingPx * (measurables.size - 1), 0)
        val lengths = ProportionalLayout.lengths(weights.map { max(it, 1.0) }, available.toDouble())
        val placeables = measurables.mapIndexed { index, measurable ->
            measurable.measure(constraints.copy(minHeight = lengths[index].toInt(), maxHeight = lengths[index].toInt()))
        }
        layout(constraints.maxWidth, constraints.maxHeight) {
            var y = 0
            placeables.forEach { placeable ->
                placeable.placeRelative(0, y)
                y += placeable.height + spacingPx
            }
        }
    }
}
