package com.example.brevet_map

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

/**
 * GPX ファイルの VIEW インテント専用の受け皿 Activity。
 * ランチャーには出さず、Files 等から開かれたときだけ起動する。
 * ここで MainActivity を前面に出す（既存タスクがあればそこに渡す）ため、
 * タスクが2つになることを防ぐ。
 */
class GpxReceiverActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uri = intent?.data
        if (uri != null) {
            val main = Intent(this, MainActivity::class.java).apply {
                data = uri
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }
            startActivity(main)
        }
        finish()
    }
}
