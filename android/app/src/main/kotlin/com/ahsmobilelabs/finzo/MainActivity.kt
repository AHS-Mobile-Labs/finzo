package com.ahsmobilelabs.finzo

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.os.Environment
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
