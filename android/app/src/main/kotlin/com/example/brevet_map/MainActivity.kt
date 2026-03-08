package com.example.brevet_map

import android.annotation.TargetApi
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownActivity
import java.io.BufferedReader
import java.io.FileInputStream
import java.io.InputStreamReader

class MainActivity : FlutterAndroidVolumeKeydownActivity() {
    private val channelName = "com.example.brevet_map/gpx"
    private val shareChannelName = "com.example.brevet_map/share"
    private var pendingGpxUri: Uri? = null
    private var pendingSharedUrl: String? = null
    private var gpxMethodChannel: MethodChannel? = null
    private var shareMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        gpxMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialGpxContent" -> {
                        val uri = pendingGpxUri ?: intent?.data
                        if (uri != null) {
                            try {
                                val content = readUriContent(uri)
                                pendingGpxUri = null
                                intent?.data = null
                                result.success(content)
                            } catch (e: Exception) {
                                result.error("READ_ERROR", e.message, null)
                            }
                        } else {
                            result.success(null)
                        }
                    }
                    "saveFileToDownloads" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        if (filePath != null && fileName != null) {
                            try {
                                val success = saveFileToDownloads(filePath, fileName)
                                result.success(success)
                            } catch (e: Exception) {
                                result.error("SAVE_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_ARGS", "filePath and fileName required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialSharedUrl" -> {
                        val url = pendingSharedUrl
                        pendingSharedUrl = null
                        clearShareIntent()
                        result.success(url)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { storePendingFromIntent(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun storePendingFromIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
                        ?.let { pendingSharedUrl = it.trim() }
                }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    if (isGpxUri(uri)) pendingGpxUri = uri
                }
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                if (intent.type == "text/plain") {
                    val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                    if (!text.isNullOrBlank()) {
                        shareMethodChannel?.invokeMethod(
                            "onSharedUrlReceived",
                            text.trim(),
                            object : MethodChannel.Result {
                                override fun success(result: Any?) {}
                                override fun error(code: String, msg: String?, details: Any?) {}
                                override fun notImplemented() {}
                            }
                        )
                        clearShareIntent()
                    }
                }
            }
            Intent.ACTION_VIEW -> {
                intent?.data?.let { uri ->
                    if (isGpxUri(uri)) {
                        try {
                            val content = readUriContent(uri)
                            gpxMethodChannel?.invokeMethod(
                                "onGpxFileReceived",
                                content,
                                object : MethodChannel.Result {
                                    override fun success(result: Any?) {}
                                    override fun error(code: String, msg: String?, details: Any?) {}
                                    override fun notImplemented() {}
                                }
                            )
                        } catch (_: Exception) {}
                    }
                }
            }
        }
    }

    private fun clearShareIntent() {
        intent?.removeExtra(Intent.EXTRA_TEXT)
        if (intent?.action == Intent.ACTION_SEND) {
            intent?.action = Intent.ACTION_MAIN
            intent?.type = null
        }
    }

    private fun isGpxUri(uri: Uri): Boolean {
        when (uri.scheme) {
            "file" -> return uri.path?.endsWith(".gpx", ignoreCase = true) == true
            "content" -> {
                contentResolver.getType(uri)?.let { type ->
                    if (type == "application/gpx+xml" || type == "text/xml") return true
                }
                return uri.toString().lowercase().contains("gpx")
            }
        }
        return false
    }

    private fun readUriContent(uri: Uri): String {
        contentResolver.openInputStream(uri)?.use { input ->
            return BufferedReader(InputStreamReader(input)).use { it.readText() }
        }
            ?: throw Exception("Could not open URI")
    }

    /** MediaStore でダウンロードフォルダにファイルを保存。fileName に拡張子を含める */
    @TargetApi(Build.VERSION_CODES.Q)
    private fun saveFileToDownloads(filePath: String, fileName: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false

        val extension = fileName.substringAfterLast('.', "").takeIf { it.isNotEmpty() }
        val mimeType = when (extension?.lowercase()) {
            "gpx" -> "application/gpx+xml"
            else -> "application/octet-stream"
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }

        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            ?: return false

        FileInputStream(filePath).use { input ->
            contentResolver.openOutputStream(uri)?.use { output ->
                input.copyTo(output)
            }
        }
        return true
    }
}
