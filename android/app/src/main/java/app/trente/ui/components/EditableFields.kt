package app.trente.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.trente.core.model.BudgetCategory
import app.trente.core.support.MoneyFormat
import app.trente.core.support.localized
import app.trente.ui.theme.TrenteColors
import app.trente.ui.theme.TrenteType
import app.trente.ui.theme.color
import app.trente.ui.theme.darken
import app.trente.ui.theme.lighten

private val editingBackground = RoundedCornerShape(12.dp)

/** A plain multi-line title field, boxed while editing, like `EditableTitleField`. */
@Composable
fun EditableTitleField(
    text: String,
    onTextChange: (String) -> Unit,
    isEditing: Boolean,
    placeholder: String,
    modifier: Modifier = Modifier,
    textStyle: TextStyle = TrenteType.title
) {
    val color = LocalContentColor.current
    Box(
        modifier
            .fillMaxWidth()
            .then(if (isEditing) Modifier.background(TrenteColors.gray.copy(alpha = 0.2f), editingBackground).padding(8.dp) else Modifier)
    ) {
        if (text.isEmpty()) {
            Text(placeholder, style = textStyle, color = TrenteColors.secondaryText.copy(alpha = 0.6f))
        }
        BasicTextField(
            value = text,
            onValueChange = onTextChange,
            enabled = isEditing,
            textStyle = textStyle.copy(color = color),
            cursorBrush = SolidColor(color),
            maxLines = 3,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/** A multi-line notes field with a prompt, like the notes `TextField`. */
@Composable
fun NotesField(
    text: String,
    onTextChange: (String) -> Unit,
    isEditing: Boolean,
    modifier: Modifier = Modifier,
    boxed: Boolean = isEditing
) {
    val color = LocalContentColor.current
    Box(
        modifier
            .fillMaxWidth()
            .then(if (boxed) Modifier.background(TrenteColors.gray.copy(alpha = 0.2f), RoundedCornerShape(10.dp)).padding(8.dp) else Modifier)
    ) {
        if (text.isEmpty()) {
            Text(localized("Add your notes here."), style = TrenteType.body, color = TrenteColors.secondaryText.copy(alpha = 0.6f))
        }
        BasicTextField(
            value = text,
            onValueChange = onTextChange,
            enabled = isEditing,
            textStyle = TrenteType.body.copy(color = color),
            cursorBrush = SolidColor(color),
            minLines = if (isEditing) 3 else 1,
            maxLines = 8,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/** The amount as an editable field, or as a capsule tag when read-only, like `EditableAmountRow`. */
@Composable
fun EditableAmountRow(amountCents: Int, onAmountChange: (Int) -> Unit, isEditing: Boolean, currencyCode: String, modifier: Modifier = Modifier) {
    if (isEditing) {
        CurrencyTextField(
            amountCents = amountCents,
            onAmountChange = onAmountChange,
            currencyCode = currencyCode,
            textStyle = TrenteType.body,
            textAlign = TextAlign.Start,
            modifier = modifier.background(TrenteColors.gray.copy(alpha = 0.2f), RoundedCornerShape(10.dp)).padding(8.dp).width(120.dp)
        )
    } else {
        Surface(
            modifier = modifier,
            shape = CircleShape,
            color = TrenteColors.gray.copy(alpha = 0.2f),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.2f))
        ) {
            Text(MoneyFormat.amountCents(amountCents, currencyCode), style = TrenteType.subheadline, modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp))
        }
    }
}

/** The category as a menu while editing, or as a colored tag, like `EditableCategoryRow`. */
@Composable
fun EditableCategoryRow(category: BudgetCategory?, onCategoryChange: (BudgetCategory) -> Unit, isEditing: Boolean, modifier: Modifier = Modifier) {
    if (isEditing) {
        var isOpen by remember { mutableStateOf(false) }
        Box(modifier.background(TrenteColors.gray.copy(alpha = 0.2f), RoundedCornerShape(10.dp))) {
            TextButton(onClick = { isOpen = true }) {
                if (category == null) {
                    Icon(Icons.Default.Add, contentDescription = null)
                    Spacer(Modifier.width(4.dp))
                    Text(localized("Add category"), color = MaterialTheme.colorScheme.onSurface)
                } else {
                    CategoryDot(category.color)
                    Spacer(Modifier.width(8.dp))
                    Text(category.displayName, color = MaterialTheme.colorScheme.onSurface)
                }
            }
            DropdownMenu(expanded = isOpen, onDismissRequest = { isOpen = false }) {
                BudgetCategory.entries.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option.displayName) },
                        leadingIcon = { CategoryDot(option.color) },
                        onClick = { isOpen = false; onCategoryChange(option) }
                    )
                }
            }
        }
    } else if (category != null) {
        val color = category.color
        Surface(
            modifier = modifier,
            shape = CircleShape,
            color = color.lighten(0.45f),
            border = BorderStroke(1.dp, color.darken(0.3f).copy(alpha = 0.2f))
        ) {
            Row(Modifier.padding(horizontal = 8.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                CategoryDot(color)
                Spacer(Modifier.width(6.dp))
                Text(category.displayName, style = TrenteType.subheadline, color = color.darken(0.6f))
            }
        }
    }
}

/** Category and amount side by side, like `EditableExpenseRow`. */
@Composable
fun EditableExpenseRow(
    category: BudgetCategory?,
    onCategoryChange: (BudgetCategory) -> Unit,
    amountCents: Int,
    onAmountChange: (Int) -> Unit,
    isEditing: Boolean,
    currencyCode: String,
    modifier: Modifier = Modifier
) {
    Row(modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        EditableCategoryRow(category = category, onCategoryChange = onCategoryChange, isEditing = isEditing)
        Spacer(Modifier.weight(1f))
        EditableAmountRow(amountCents = amountCents, onAmountChange = onAmountChange, isEditing = isEditing, currencyCode = currencyCode)
    }
}
