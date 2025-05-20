package com.shift.app.mobile

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel

class SyncService : Service() {

    private val CHANNEL = "shift_app/sync"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i("SyncService", "🔁 התחלת שירות סנכרון")

        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(applicationContext)
        flutterLoader.ensureInitializationComplete(applicationContext, null)

        val flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("syncNow", null)

        stopSelf() // סיים את השירות לאחר הסנכרון
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
