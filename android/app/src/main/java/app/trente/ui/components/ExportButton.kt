package app.trente.ui.components

import android.content.Intent
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Share
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.FileProvider
import app.trente.core.model.TrenteStore
import app.trente.core.services.export.TransactionsCSVFile
import app.trente.core.support.localized
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Writes the CSV (or the zip with images) and opens the share sheet, like `ExportButton`. */
@Composable
fun ExportButton(title: String, file: TransactionsCSVFile, store: TrenteStore, modifier: Modifier = Modifier, enabled: Boolean = true) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var isWriting by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    TrentePrimaryButton(
        text = title,
        icon = Icons.Default.Share,
        narrow = true,
        enabled = enabled && !isWriting,
        modifier = modifier,
        onClick = {
            if (isWriting) return@TrentePrimaryButton
            isWriting = true
            scope.launch {
                try {
                    store.save()
                    val exportsDirectory = File(context.cacheDir, "Exports")
                    val written = withContext(Dispatchers.IO) { file.write(store, exportsDirectory) }
                    val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", written)
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = if (written.name.endsWith(".zip")) "application/zip" else "text/csv"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        putExtra(Intent.EXTRA_SUBJECT, written.nameWithoutExtension)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    context.startActivity(Intent.createChooser(intent, written.name))
                } catch (exception: Exception) {
                    error = exception.localizedMessage ?: exception.toString()
                } finally {
                    isWriting = false
                }
            }
        }
    )
    ErrorAlert(message = error, onDismiss = { error = null }, title = localized("Export Failed"))
}
