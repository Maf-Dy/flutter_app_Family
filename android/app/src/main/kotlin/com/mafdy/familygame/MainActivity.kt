package com.mafdy.familygame

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var hotspot: LocalHotspot? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LocalHotspot.CHANNEL)
        hotspot = LocalHotspot(applicationContext, channel).also { channel.setMethodCallHandler(it) }
    }

    override fun onDestroy() {
        hotspot?.stop()
        super.onDestroy()
    }
}
