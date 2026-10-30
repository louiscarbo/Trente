package app.trente.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetCategory
import app.trente.core.presentation.RepartitionSplit
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.adjusted
import app.trente.ui.theme.color
import app.trente.ui.theme.darken
import app.trente.ui.theme.lighten

/**
 * Splits an amount across the three categories with a slider per category, like the iOS component.
 * The amount to split is shown in a bar that fills up as the split completes.
 */
@Composable
fun IncomeRepartitionComponent(
    repartition: Map<BudgetCategory, Int>,
    amountToSplit: Int,
    currencyCode: String,
    onRepartitionChange: (Map<BudgetCategory, Int>) -> Unit,
    onCompleteChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val split = RepartitionSplit(amountToSplit, repartition)
    val remaining = split.remaining
    LaunchedEffect(remaining) { onCompleteChange(remaining == 0) }

    fun update(block: RepartitionSplit.() -> Unit) {
        val next = RepartitionSplit(amountToSplit, repartition)
        next.block()
        onRepartitionChange(next.values)
    }

    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (enabled) {
            AmountToSplitBar(remaining = remaining, total = amountToSplit, currencyCode = currencyCode)
        }
        BudgetCategory.entries.forEach { category ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (enabled) {
                    SliderButton(
                        icon = Icons.Default.Remove,
                        color = category.color,
                        enabled = split.amount(category) > 0,
                        contentDescription = localized("Decrease %@", category.shortName),
                        onClick = { update { decrease(category) } }
                    )
                }
                RepartitionSlider(
                    categoryName = category.shortName,
                    color = category.color,
                    value = split.amount(category),
                    total = amountToSplit,
                    maxValue = split.amount(category) + remaining,
                    currencyCode = currencyCode,
                    enabled = enabled,
                    onValueChange = { update { set(category, it) } },
                    modifier = Modifier.weight(1f)
                )
                if (enabled) {
                    SliderButton(
                        icon = Icons.Default.Add,
                        color = category.color,
                        enabled = remaining > 0,
                        contentDescription = localized("Increase %@", category.shortName),
                        onClick = { update { increase(category) } }
                    )
                }
            }
        }
    }
}

@Composable
private fun AmountToSplitBar(remaining: Int, total: Int, currencyCode: String) {
    val pink = TrenteColors.pink
    val fraction by animateFloatAsState(if (total > 0) remaining.toFloat() / total else 0f, label = "remainingFraction")
    val isAlmostDone = remaining in 1..99
    Box(
        Modifier
            .fillMaxWidth()
            .clip(CircleShape)
            .background(pink.lighten(0.25f))
            .border(BorderStroke(3.dp, pink.darken(0.1f)), CircleShape)
    ) {
        Box(Modifier.matchParentSize()) {
            Box(Modifier.fillMaxWidth(fraction.coerceIn(0.01f, 1f)).fillMaxHeight().background(pink))
        }
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                if (remaining > 0) Icons.Default.Warning else Icons.Default.CheckCircle,
                contentDescription = null,
                tint = pink.darken(0.6f),
                modifier = Modifier.size(18.dp)
            )
            Spacer(Modifier.width(6.dp))
            Text(
                localized("Amount to split"),
                style = TrenteType.subheadline.copy(fontWeight = if (isAlmostDone) FontWeight.Bold else FontWeight.Normal),
                color = pink.darken(0.6f)
            )
            Spacer(Modifier.weight(1f))
            Text(
                MoneyFormat.amountCents(remaining, currencyCode),
                style = TrenteType.subheadline.copy(fontWeight = if (isAlmostDone) FontWeight.Bold else FontWeight.Normal),
                color = pink.darken(0.6f)
            )
        }
    }
}

@Composable
private fun SliderButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color,
    enabled: Boolean,
    contentDescription: String,
    onClick: () -> Unit
) {
    Box(
        Modifier
            .size(width = 40.dp, height = 64.dp)
            .clip(CardShape)
            .background(color)
            .border(BorderStroke(3.dp, color.darken(0.1f)), CardShape),
        contentAlignment = Alignment.Center
    ) {
        IconButton(onClick = onClick, enabled = enabled) {
            Icon(icon, contentDescription = contentDescription, tint = color.darken(0.8f), modifier = Modifier.alpha(if (enabled) 1f else 0.3f))
        }
    }
}

/** A bar filled up to `value / total`; dragging anywhere sets the value in whole units. */
@Composable
fun RepartitionSlider(
    categoryName: String,
    color: Color,
    value: Int,
    total: Int,
    maxValue: Int,
    currencyCode: String,
    onValueChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    var widthPx by remember { androidx.compose.runtime.mutableIntStateOf(1) }
    val fraction by animateFloatAsState(if (total > 0) value.toFloat() / total else 0f, label = "sliderFraction")
    val proportion = if (total > 0) value.toDouble() / total else 0.0
    val textColor = color.darken(0.8f)
    Box(
        modifier
            .height(64.dp)
            .clip(CardShape)
            .background(color.adjustedTrack())
            .border(BorderStroke(3.dp, color.darken(0.1f)), CardShape)
            .onSizeChanged { widthPx = it.width }
            .pointerInput(enabled, total, maxValue) {
                if (!enabled) return@pointerInput
                detectDragGestures { change, _ ->
                    change.consume()
                    onValueChange(RepartitionSplit.dragValue((change.position.x / widthPx).toDouble(), total, maxValue))
                }
            }
            .pointerInput(enabled, total, maxValue) {
                if (!enabled) return@pointerInput
                detectTapGestures { offset ->
                    onValueChange(RepartitionSplit.dragValue((offset.x / widthPx).toDouble(), total, maxValue))
                }
            },
        contentAlignment = Alignment.Center
    ) {
        Box(Modifier.fillMaxWidth(fraction.coerceIn(0f, 1f)).fillMaxHeight().background(color))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("$categoryName - ${(proportion * 100).toInt()}%", style = TrenteType.subheadline.copy(fontWeight = FontWeight.Bold), color = textColor)
            Text(MoneyFormat.budget(value / 100.0, currencyCode), style = TrenteType.title3, color = textColor)
        }
    }
}

private fun Color.adjustedTrack(): Color = adjusted(brightnessDrop = -0.10f, saturationBoost = -0.2f)
