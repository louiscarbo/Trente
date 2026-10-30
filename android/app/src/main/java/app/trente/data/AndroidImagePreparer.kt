package app.trente.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import androidx.exifinterface.media.ExifInterface
import app.trente.core.services.ImagePreparer
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Shrinks a picked photo to 2048px and JPEG 80%, like the iOS `ImageAttachment`, keeping its EXIF orientation. */
object AndroidImagePreparer : ImagePreparer {
    override suspend fun prepare(data: ByteArray): ByteArray = withContext(Dispatchers.Default) { downscaled(data) ?: data }

    fun downscaled(data: ByteArray, maximumPixelSize: Int = ImagePreparer.MAXIMUM_PIXEL_SIZE): ByteArray? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sampleSize = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sampleSize * 2) >= maximumPixelSize) {
            sampleSize *= 2
        }
        val decoded = BitmapFactory.decodeByteArray(data, 0, data.size, BitmapFactory.Options().apply { inSampleSize = sampleSize }) ?: return null
        val largest = maxOf(decoded.width, decoded.height)
        val scaled = if (largest > maximumPixelSize) {
            val scale = maximumPixelSize.toFloat() / largest
            Bitmap.createScaledBitmap(decoded, (decoded.width * scale).toInt(), (decoded.height * scale).toInt(), true)
        } else {
            decoded
        }
        val oriented = rotated(scaled, orientation(data))
        val output = ByteArrayOutputStream()
        oriented.compress(Bitmap.CompressFormat.JPEG, ImagePreparer.COMPRESSION_QUALITY, output)
        val encoded = output.toByteArray()
        return if (encoded.size < data.size || oriented !== decoded) encoded else data
    }

    private fun orientation(data: ByteArray): Int = try {
        ExifInterface(data.inputStream()).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
    } catch (exception: Exception) {
        ExifInterface.ORIENTATION_NORMAL
    }

    private fun rotated(bitmap: Bitmap, orientation: Int): Bitmap {
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /** Reads the bytes of a picked photo. */
    suspend fun read(context: Context, uri: Uri): ByteArray? = withContext(Dispatchers.IO) {
        context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
    }
}
