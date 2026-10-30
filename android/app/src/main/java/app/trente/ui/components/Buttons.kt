package app.trente.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.trente.ui.theme.TrenteType
import androidx.compose.foundation.clickable

/** The inverted pill button of iOS: dark on light, light on dark. */
@Composable
fun TrentePrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    narrow: Boolean = false,
    destructive: Boolean = false
) {
    val isDark = isSystemInDarkTheme()
    val container = when {
        destructive -> MaterialTheme.colorScheme.error
        isDark -> Color.White
        else -> Color(0xFF1C1C1E)
    }
    val content = if (destructive || !isDark) Color.White else Color.Black
    // The inner rim of the iOS capsule: black on light, white on dark.
    val rim = (if (isDark) Color.White else Color.Black).copy(alpha = if (enabled) 0.6f else 0.3f)
    Button(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        border = BorderStroke(3.dp, rim),
        modifier = modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(
            containerColor = container,
            contentColor = content,
            disabledContainerColor = container.copy(alpha = 0.5f),
            disabledContentColor = content.copy(alpha = 0.7f)
        ),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = if (narrow) 10.dp else 16.dp)
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text, style = if (narrow) TrenteType.title3 else TrenteType.title2, textAlign = TextAlign.Center)
    }
}

/** The neutral pill button of iOS. */
@Composable
fun TrenteSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    enabled: Boolean = true,
    narrow: Boolean = false
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        shape = CircleShape,
        modifier = modifier.fillMaxWidth(),
        border = BorderStroke(3.dp, onSurface.copy(alpha = if (enabled) 0.2f else 0.1f)),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer,
            contentColor = onSurface,
            disabledContentColor = onSurface.copy(alpha = 0.5f)
        ),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = if (narrow) 10.dp else 16.dp)
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text, style = TrenteType.title3, textAlign = TextAlign.Center)
    }
}

/** A toggle drawn as a check circle followed by its label, like `TrenteToggleStyle`. */
@Composable
fun TrenteToggle(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    label: @Composable () -> Unit
) {
    val tint by animateColorAsState(
        if (checked) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
        label = "toggleTint"
    )
    val scale by animateFloatAsState(if (checked) 1f else 0.95f, spring(dampingRatio = 0.5f), label = "toggleScale")
    Row(
        modifier = modifier
            .semantics { role = Role.Switch }
            .clickable(enabled = enabled) { onCheckedChange(!checked) },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            if (checked) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(28.dp).scale(scale)
        )
        Spacer(Modifier.width(10.dp))
        androidx.compose.runtime.CompositionLocalProvider(
            androidx.compose.material3.LocalContentColor provides tint
        ) {
            label()
        }
    }
}

/** Scales a card down while pressed, like `PressableCardButtonStyle`. */
@Composable
fun Modifier.pressableCard(interactionSource: MutableInteractionSource): Modifier {
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(if (isPressed) 0.97f else 1f, spring(dampingRatio = 0.6f), label = "pressScale")
    return this.scale(scale)
}

@Composable
fun rememberPressInteraction(): MutableInteractionSource = remember { MutableInteractionSource() }
