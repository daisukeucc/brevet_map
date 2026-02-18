package com.example.brevet_map

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import dev.darttools.flutter_android_volume_keydown.FlutterAndroidVolumeKeydownActivity
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterAndroidVolumeKeydownActivity() {
    private val channelName = "com.example.brevet_map/gpx"
    private var pendingGpxUri: Uri? = null
    private var gpxMethodChannel: MethodChannel? = null

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
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.data?.let { uri ->
            if (isGpxUri(uri)) pendingGpxUri = uri
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.data?.let { uri ->
            if (isGpxUri(uri)) {
                pendingGpxUri = uri
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
}
