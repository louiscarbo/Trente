package app.trente.core.services

import app.trente.core.support.localized
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch

/** Shrinks a picked photo before it is stored. The app decodes with Android; the core keeps the bytes as they are. */
fun interface ImagePreparer {
    suspend fun prepare(data: ByteArray): ByteArray

    companion object {
        const val MAXIMUM_PIXEL_SIZE = 2048
        const val COMPRESSION_QUALITY = 80

        val identity = ImagePreparer { it }
    }
}

/** Loads a picked photo; a newer pick wins over a slower older one. */
class ImageAttachmentLoader(
    private val scope: CoroutineScope,
    private val preparer: ImagePreparer = ImagePreparer.identity
) {
    var isLoading: Boolean = false
        private set

    var error: String? = null

    var currentLoad: Job? = null
        private set

    fun load(loadData: suspend () -> ByteArray?, onLoaded: (ByteArray) -> Unit) {
        currentLoad?.cancel()
        isLoading = true
        currentLoad = scope.launch {
            val loadedData = try {
                loadData()
            } catch (exception: CancellationException) {
                throw exception
            } catch (exception: Exception) {
                null
            }
            val preparedData = loadedData?.let { preparer.prepare(it) }
            ensureActive()
            if (preparedData != null) {
                onLoaded(preparedData)
            } else {
                error = localized("The image could not be loaded. Please try again.")
            }
            isLoading = false
        }
    }
}
