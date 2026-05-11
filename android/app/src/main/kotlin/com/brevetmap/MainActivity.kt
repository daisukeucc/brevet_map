package com.brevetmap

import android.annotation.TargetApi
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.view.KeyEvent
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileInputStream
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets

class MainActivity : FlutterFragmentActivity() {
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        val sink = FlutterAndroidVolumeKeydownPlugin.eventSink
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN && sink != null) {
            sink.success(true)
            return true
        }
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP && sink != null) {
            sink.success(false)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
    private val channelName = "com.brevetmap/gpx"
    private val shareChannelName = "com.brevetmap/share"
    private var pendingGpxUri: Uri? = null
    private var pendingSharedUrl: String? = null
    private var gpxMethodChannel: MethodChannel? = null
    private var shareMethodChannel: MethodChannel? = null

    private fun gpxBasenameFromUri(uri: Uri): String? {
        val name = when (uri.scheme) {
            "file" -> uri.lastPathSegment
            else -> {
                var n: String? = null
                contentResolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME),
                    null,
                    null,
                    null,
                )?.use { c ->
                    if (c.moveToFirst()) {
                        val i = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (i >= 0) n = c.getString(i)
                    }
                }
                n
            }
        } ?: return null
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return null
        return if (trimmed.endsWith(".gpx", true)) {
            trimmed.substring(0, trimmed.length - 4).trim()
        } else {
            trimmed
        }.takeIf { it.isNotEmpty() }
    }

    private fun gpxPayloadArguments(content: String, uri: Uri): Map<String, String> {
        val map = HashMap<String, String>()
        map["content"] = content
        gpxBasenameFromUri(uri)?.let { map["basename"] = it }
        return map
    }

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
                                result.success(gpxPayloadArguments(content, uri))
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
        intent?.let {
            it.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            storePendingFromIntent(it)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        handleIntent(intent)
    }

    private fun storePendingFromIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                when (intent.type) {
                    "text/plain" -> {
                        intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
                            ?.let { pendingSharedUrl = it.trim() }
                    }
                    "application/gpx+xml", "text/xml", "application/octet-stream" -> {
                        getStreamUri(intent)?.let { uri ->
                            if (isGpxUri(uri)) pendingGpxUri = uri
                        }
                    }
                    else -> {
                        if (intent.type?.contains("xml") == true || intent.type == "*/*") {
                            getStreamUri(intent)?.let { uri ->
                                if (isGpxUri(uri)) pendingGpxUri = uri
                            }
                        }
                    }
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
                when (intent.type) {
                    "text/plain" -> {
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
                    else -> {
                        // image/* (スクリーンショット等) は GPX ではないのでスキップ
                        if (intent.type?.startsWith("image/") == true) return
                        getStreamUri(intent)?.let { uri ->
                            try {
                                val content = readUriContent(uri)
                                if (content.isNotEmpty()) {
                                    gpxMethodChannel?.invokeMethod(
                                        "onGpxFileReceived",
                                        gpxPayloadArguments(content, uri),
                                        object : MethodChannel.Result {
                                            override fun success(result: Any?) {}
                                            override fun error(code: String, msg: String?, details: Any?) {}
                                            override fun notImplemented() {}
                                        }
                                    )
                                }
                            } catch (_: Exception) {}
                        }
                    }
                }
            }
            Intent.ACTION_VIEW -> {
                intent?.data?.let { uri ->
                    // image/* (スクリーンショット等) は GPX ではないのでスキップ
                    if (contentResolver.getType(uri)?.startsWith("image/") == true) return@let
                    try {
                        val content = readUriContent(uri)
                        if (content.isNotEmpty()) {
                            gpxMethodChannel?.invokeMethod(
                                "onGpxFileReceived",
                                gpxPayloadArguments(content, uri),
                                object : MethodChannel.Result {
                                    override fun success(result: Any?) {}
                                    override fun error(code: String, msg: String?, details: Any?) {}
                                    override fun notImplemented() {}
                                }
                            )
                        }
                    } catch (_: Exception) {}
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun getStreamUri(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
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
            // GPX は UTF-8 が標準。プラットフォーム既定（端末・環境により異なる）で読むと日本語が壊れる。
            return BufferedReader(InputStreamReader(input, StandardCharsets.UTF_8)).use { it.readText() }
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
