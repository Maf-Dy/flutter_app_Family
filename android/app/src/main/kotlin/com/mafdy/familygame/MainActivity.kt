package com.mafdy.familygame

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var hotspot: LocalHotspot? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LocalHotspot.CHANNEL)
        hotspot = LocalHotspot(applicationContext, channel).also { channel.setMethodCallHandler(it) }
        // Pass the phone: secret names stay out of screenshots and the recent-apps preview.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "family_game/secure_screen").setMethodCallHandler { call, result ->
            if (call.method != "setSecure") return@setMethodCallHandler result.notImplemented()
            if (call.arguments == true) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
            result.success(null)
        }
    }

    override fun onDestroy() {
        hotspot?.dispose()
        super.onDestroy()
    }
}
