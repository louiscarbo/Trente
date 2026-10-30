package app.trente.ui.components

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.trente.core.support.localized
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Decodes image bytes off the main thread; null until decoded. */
@Composable
fun rememberImageBitmap(data: ByteArray?, key: Any? = data?.size): ImageBitmap? {
    val bitmap by produceState<ImageBitmap?>(initialValue = null, key1 = key) {
        value = if (data == null) null else withContext(Dispatchers.Default) {
            val options = BitmapFactory.Options().apply { inSampleSize = 2 }
            BitmapFactory.decodeByteArray(data, 0, data.size, options)?.asImageBitmap()
        }
    }
    return bitmap
}

/** A full-screen, pinch-to-zoom photo viewer, like `ZoomableImageView`. */
@Composable
fun ZoomableImageDialog(image: ImageBitmap, onDismiss: () -> Unit) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(androidx.compose.ui.geometry.Offset.Zero) }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black)
                .pointerInput(Unit) {
                    detectTransformGestures { _, pan, zoom, _ ->
                        scale = (scale * zoom).coerceIn(1f, 5f)
                        offset = if (scale > 1f) offset + pan else androidx.compose.ui.geometry.Offset.Zero
                    }
                }
        ) {
            Image(
                bitmap = image,
                contentDescription = localized("Photo"),
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer(scaleX = scale, scaleY = scale, translationX = offset.x, translationY = offset.y)
            )
            IconButton(onClick = onDismiss, modifier = Modifier.align(Alignment.TopEnd).padding(12.dp)) {
                Icon(Icons.Default.Close, contentDescription = localized("Close"), tint = Color.White)
            }
        }
    }
}

/** A thumbnail that opens the viewer when tapped. */
@Composable
fun AttachmentThumbnail(image: ImageBitmap, modifier: Modifier = Modifier, contentScale: ContentScale = ContentScale.Crop) {
    var isShowing by remember { mutableStateOf(false) }
    Image(
        bitmap = image,
        contentDescription = localized("Show Image"),
        contentScale = contentScale,
        modifier = modifier.clickable { isShowing = true }
    )
    if (isShowing) {
        ZoomableImageDialog(image = image, onDismiss = { isShowing = false })
    }
}
