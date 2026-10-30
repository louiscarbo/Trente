package app.trente.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.trente.core.support.localized
import app.trente.ui.theme.CardShape
import app.trente.ui.theme.Dimens
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import kotlinx.coroutines.launch

/** The standard card: a rounded box with a 3dp border and a headline label, like `TrenteGroupBoxStyle`. */
@Composable
fun TrenteCard(
    modifier: Modifier = Modifier,
    label: String? = null,
    icon: ImageVector? = null,
    iconTint: Color = MaterialTheme.colorScheme.onSurface,
    withPadding: Boolean = true,
    trailing: (@Composable () -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = modifier.shadow(2.dp, CardShape, clip = false).fillMaxWidth(),
        shape = CardShape,
        color = MaterialTheme.colorScheme.surfaceContainer,
        border = BorderStroke(Dimens.cardBorder, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f))
    ) {
        Column(
            modifier = if (withPadding) Modifier.padding(16.dp) else Modifier,
            verticalArrangement = Arrangement.spacedBy(Dimens.spacingMedium)
        ) {
            if (label != null) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = if (withPadding) Modifier.fillMaxWidth() else Modifier.fillMaxWidth().padding(16.dp)
                ) {
                    if (icon != null) {
                        Icon(icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(8.dp))
                    }
                    Text(label, style = TrenteType.headline)
                    if (trailing != null) {
                        Spacer(Modifier.weight(1f))
                        trailing()
                    }
                }
            }
            content()
        }
    }
}

/** A rounded background for list rows, like `TrenteListBackgroundView`. */
@Composable
fun TrenteListBackground(modifier: Modifier = Modifier, selected: Boolean = false, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = CardShape,
        color = MaterialTheme.colorScheme.surfaceContainer,
        border = BorderStroke(Dimens.cardBorder, MaterialTheme.colorScheme.onSurface.copy(alpha = if (selected) 0.5f else 0.2f))
    ) {
        Column(content = content)
    }
}

/** A card with a destructive button and a confirmation, like `DeleteSectionBox`. */
@Composable
fun DeleteSectionBox(
    title: String,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    message: String = localized("This action cannot be undone.")
) {
    var isConfirming by remember { mutableStateOf(false) }
    TrenteCard(modifier = modifier, label = title, icon = Icons.Default.Delete) {
        Text(message, style = TrenteType.subheadline, color = TrenteColors.secondaryText)
        TrentePrimaryButton(text = title, icon = Icons.Default.Delete, narrow = true, destructive = true, onClick = { isConfirming = true })
    }
    if (isConfirming) {
        DeleteConfirmationDialog(message = message, onDismiss = { isConfirming = false }, onDelete = { isConfirming = false; onDelete() })
    }
}

@Composable
fun DeleteConfirmationDialog(
    onDismiss: () -> Unit,
    onDelete: () -> Unit,
    message: String = localized("This action cannot be undone."),
    title: String = localized("Are you sure?"),
    confirmText: String = localized("Delete")
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            TextButton(onClick = onDelete, colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                Text(confirmText)
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(localized("Cancel")) } }
    )
}

@Composable
fun ErrorAlert(message: String?, onDismiss: () -> Unit, title: String = localized("An error occurred"), retry: (() -> Unit)? = null) {
    if (message == null) return
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = {
            if (retry != null) {
                TextButton(onClick = { onDismiss(); retry() }) { Text(localized("Retry")) }
            } else {
                TextButton(onClick = onDismiss) { Text(localized("OK")) }
            }
        },
        dismissButton = if (retry != null) {
            { TextButton(onClick = onDismiss) { Text(localized("Cancel")) } }
        } else null
    )
}

/** Dims and locks content behind the paywall, like `.requiresTrentePlus(.inline)`. */
@Composable
fun RequiresTrentePlus(
    isSubscribed: Boolean,
    onShowPaywall: () -> Unit,
    modifier: Modifier = Modifier,
    isRequired: Boolean = true,
    content: @Composable () -> Unit
) {
    val isLocked = isRequired && !isSubscribed
    Box(modifier) {
        Box(Modifier.alpha(if (isLocked) 0.4f else 1f)) { content() }
        if (isLocked) {
            Box(
                Modifier
                    .matchParentSize()
                    .clickable(onClick = onShowPaywall),
                contentAlignment = Alignment.CenterEnd
            ) {
                TrentePlusPill(modifier = Modifier.padding(end = 12.dp))
            }
        }
    }
}

@Composable
fun TrentePlusPill(modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier,
        shape = CircleShape,
        color = MaterialTheme.colorScheme.surfaceContainerHigh,
        border = BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f))
    ) {
        Row(Modifier.padding(horizontal = 10.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Lock, contentDescription = localized("Requires Trente+"), modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(4.dp))
            Text("Trente+", style = TrenteType.caption.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold))
        }
    }
}

/** Blurs a whole section behind the paywall, like `.requiresTrentePlus(.section(prompt:))`. */
@Composable
fun RequiresTrentePlusSection(
    isSubscribed: Boolean,
    prompt: String,
    onShowPaywall: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Box(modifier) {
        Box(if (isSubscribed) Modifier else Modifier.alpha(0.8f).blur(3.dp)) { content() }
        if (!isSubscribed) {
            Box(Modifier.matchParentSize().clickable(onClick = {}), contentAlignment = Alignment.Center) {
                Button(onClick = onShowPaywall, shape = CircleShape, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.onSurface, contentColor = MaterialTheme.colorScheme.surface)) {
                    Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(prompt, style = TrenteType.title3)
                }
            }
        }
    }
}

/** A row that opens a link, with the ↗ arrow of `ExternalLinkLabel`. */
@Composable
fun ExternalLinkRow(title: String, icon: ImageVector?, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(12.dp))
        }
        Text(title, style = TrenteType.body, modifier = Modifier.weight(1f))
        Icon(Icons.AutoMirrored.Filled.OpenInNew, contentDescription = null, tint = TrenteColors.secondaryText, modifier = Modifier.size(16.dp))
    }
}

/** A title with a dropdown on the trailing side, like `LabeledPicker`. */
@Composable
fun <T> LabeledPicker(
    title: String,
    selection: T,
    options: List<T>,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    optionTitle: (T) -> String
) {
    var isOpen by remember { mutableStateOf(false) }
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = TrenteType.body)
        Spacer(Modifier.weight(1f))
        Box {
            TextButton(onClick = { isOpen = true }, enabled = enabled) {
                Text(optionTitle(selection), color = MaterialTheme.colorScheme.onSurface)
                Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = MaterialTheme.colorScheme.onSurface)
            }
            DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
                options.forEach { option ->
                    DropdownMenuItem(text = { Text(optionTitle(option)) }, onClick = { isOpen = false; onSelect(option) })
                }
            }
        }
    }
}

@Composable
fun CategoryDot(color: Color, size: Dp = 10.dp, modifier: Modifier = Modifier) {
    Box(modifier.size(size).clip(CircleShape).background(color))
}

/** The pig or rocket sticker, rotated with a shadow, like `StickerView`. */
@Composable
fun Sticker(resource: Int, modifier: Modifier = Modifier, rotation: Float = -8f) {
    Image(
        painter = painterResource(resource),
        contentDescription = null,
        contentScale = ContentScale.Fit,
        modifier = modifier.rotate(rotation).shadow(0.dp)
    )
}

/** Dots under a pager, like `PageIndicator`. */
@Composable
fun PageIndicator(pageCount: Int, currentPage: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
        repeat(pageCount) { index ->
            val color = if (index == currentPage) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.3f)
            Box(
                Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(color)
                    .clickable { onSelect(index) }
            )
        }
    }
}

/** A horizontal paging carousel of cards with a page indicator below, like `CardCarousel`. */
@Composable
fun CardCarousel(
    state: PagerState,
    modifier: Modifier = Modifier,
    contentPadding: Dp = 16.dp,
    page: @Composable (Int) -> Unit
) {
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        HorizontalPager(
            state = state,
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = contentPadding),
            pageSpacing = 20.dp,
            verticalAlignment = Alignment.Top
        ) { index -> page(index) }
        PageIndicator(pageCount = state.pageCount, currentPage = state.currentPage, onSelect = { scope.launch { state.animateScrollToPage(it) } })
    }
}

/** Dims and disables content, like `.disabled(true)` in SwiftUI. */
@Composable
fun Disabled(isDisabled: Boolean, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier) {
        content()
        if (isDisabled) {
            Box(Modifier.matchParentSize().clickable(enabled = true, onClick = {}, indication = null, interactionSource = remember { androidx.compose.foundation.interaction.MutableInteractionSource() }))
        }
    }
}
