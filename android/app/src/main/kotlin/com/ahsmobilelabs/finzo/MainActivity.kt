package com.ahsmobilelabs.finzo

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val shareChannel = "com.ahsmobilelabs.finzo/share"
    private val storageChannel = "com.ahsmobilelabs.finzo/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareLinktreeQr" -> shareLinktreeQr(call, result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDocumentsDirectory" -> result.success(getPublicDocumentsDirectory())
                    "savePublicFile" -> savePublicFile(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getPublicDocumentsDirectory(): String? {
        return try {
            val documentsDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS,
            )

            if (!documentsDir.exists() && !documentsDir.mkdirs()) {
                return null
            }

            documentsDir.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun savePublicFile(call: MethodCall, result: MethodChannel.Result) {
        val fileName = cleanFileName(call.argument<String>("fileName").orEmpty())
        val mimeType = call.argument<String>("mimeType").orEmpty()
            .ifBlank { "application/octet-stream" }
        val subdirectory = cleanRelativeDirectory(
            call.argument<String>("subdirectory").orEmpty(),
        )
        val bytes = call.argument<ByteArray>("bytes")

        if (fileName.isBlank()) {
            result.error("missing_file_name", "Export file name was missing.", null)
            return
        }

        if (bytes == null) {
            result.error("missing_bytes", "Export file data was missing.", null)
            return
        }

        try {
            val savedPath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                savePublicFileWithMediaStore(fileName, mimeType, subdirectory, bytes)
            } else {
                savePublicFileWithFileApi(fileName, subdirectory, bytes)
            }
            result.success(savedPath)
        } catch (e: Exception) {
            result.error(
                "save_public_file_failed",
                e.localizedMessage ?: "Unable to save the export file.",
                null,
            )
        }
    }

    private fun savePublicFileWithMediaStore(
        fileName: String,
        mimeType: String,
        subdirectory: String,
        bytes: ByteArray,
    ): String {
        val relativePath = buildRelativeDocumentsPath(subdirectory)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val resolver = applicationContext.contentResolver
        val uri = resolver.insert(MediaStore.Files.getContentUri("external"), values)
            ?: throw IllegalStateException("Could not create export file.")

        resolver.openOutputStream(uri)?.use { stream ->
            stream.write(bytes)
        } ?: throw IllegalStateException("Could not open export file.")

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)

        return "${relativePath.trimEnd('/')}/$fileName"
    }

    private fun savePublicFileWithFileApi(
        fileName: String,
        subdirectory: String,
        bytes: ByteArray,
    ): String {
        val documentsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOCUMENTS,
        )
        val finzoDir = if (subdirectory.isBlank()) {
            File(documentsDir, "Finzo")
        } else {
            File(documentsDir, "Finzo/$subdirectory")
        }

        if (!finzoDir.exists() && !finzoDir.mkdirs()) {
            throw IllegalStateException("Could not create ${finzoDir.absolutePath}.")
        }

        val target = File(finzoDir, fileName)
        target.writeBytes(bytes)
        return target.absolutePath
    }

    private fun buildRelativeDocumentsPath(subdirectory: String): String {
        val parts = mutableListOf(Environment.DIRECTORY_DOCUMENTS, "Finzo")
        if (subdirectory.isNotBlank()) {
            parts.addAll(subdirectory.split("/").filter { it.isNotBlank() })
        }
        return parts.joinToString("/") + "/"
    }

    private fun cleanFileName(value: String): String {
        val cleaned = value.replace(Regex("""[\\/:*?"<>|]"""), "_").trim()
        return cleaned.ifBlank { "finzo_export" }
    }

    private fun cleanRelativeDirectory(value: String): String {
        return value
            .split(Regex("""[/\\]+"""))
            .map { it.replace(Regex("""[\\/:*?"<>|]"""), "_").trim() }
            .filter { it.isNotBlank() && it != "." && it != ".." }
            .joinToString("/")
    }

    private fun shareLinktreeQr(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text").orEmpty()
        val imagePath = call.argument<String>("imagePath")

        if (imagePath.isNullOrBlank()) {
            result.error("missing_image", "QR image was not prepared for sharing.", null)
            return
        }

        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            result.error("missing_image", "QR image file was not found.", null)
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.shareprovider",
                imageFile,
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "image/png"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_STREAM, uri)
                clipData = ClipData.newUri(contentResolver, "AHS Mobile Labs QR", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(Intent.createChooser(shareIntent, "Share Link and QR"))
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("no_share_target", "No app is available to share this QR code.", null)
        } catch (e: Exception) {
            result.error("share_failed", e.localizedMessage ?: "Unable to share this QR code.", null)
        }
    }
}
