package com.shift.app.mobile

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "shift_app/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine) // ✅ חובה להשאיר
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "startSyncService") {
                try {
                    val intent = Intent(this, SyncService::class.java)
                    startService(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SERVICE_ERROR", "Failed to start service", e.message)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // כאן ניתן בעתיד להוסיף קוד שירוץ עם פתיחת הפעילות
    }
}
