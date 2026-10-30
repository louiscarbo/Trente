package app.trente.ui.components

import androidx.compose.foundation.layout.RowScope
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.style.TextOverflow
import app.trente.core.support.localized

/** The inline navigation bar: a title, a back or close button, and actions. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TrenteTopBar(
    title: String,
    onBack: (() -> Unit)? = null,
    closeStyle: CloseStyle = CloseStyle.BACK,
    actions: @Composable RowScope.() -> Unit = {}
) {
    TopAppBar(
        title = { Text(title, maxLines = 1, overflow = TextOverflow.Ellipsis) },
        navigationIcon = {
            if (onBack != null) {
                IconButton(onClick = onBack) {
                    when (closeStyle) {
                        CloseStyle.BACK -> Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = localized("Back"))
                        CloseStyle.CLOSE -> Icon(Icons.Default.KeyboardArrowDown, contentDescription = localized("Close"))
                        CloseStyle.CANCEL -> Icon(Icons.Default.Close, contentDescription = localized("Cancel"))
                    }
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
    )
}

enum class CloseStyle { BACK, CLOSE, CANCEL }
