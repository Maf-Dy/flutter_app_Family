package com.mafdy.familygame

import android.annotation.TargetApi
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Starts Android's local-only hotspot so friends can join the room without a router.
 *
 * Marshalling only: permission decisions and error wording live in Dart
 * (lib/features/room/data/device_network.dart). Error codes sent back:
 * unsupported, permission, incompatible, disallowed, no_channel, generic.
 */
class LocalHotspot(context: Context, private val channel: MethodChannel) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "family_game/hotspot"
    }

    private val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "start" -> start(result)
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun stop() {
        // A reservation only exists on Android 8+, but lint cannot see that.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) reservation?.close()
        reservation = null
    }

    private fun start(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", null, null)
            return
        }
        reservation?.let {
            result.success(credentials(it))
            return
        }
        // The callback can fire more than once (for example onStarted, then onStopped);
        // a MethodChannel.Result may only be answered once.
        var replied = false
        fun reply(answer: () -> Unit) {
            if (!replied) {
                replied = true
                answer()
            }
        }
        try {
            wifi.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(started: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = started
                    reply { result.success(credentials(started)) }
                }

                override fun onStopped() {
                    reservation = null
                    channel.invokeMethod("stopped", null)
                }

                override fun onFailed(reason: Int) {
                    reply { result.error(failureCode(reason), null, null) }
                }
            }, Handler(Looper.getMainLooper()))
        } catch (e: SecurityException) {
            reply { result.error("permission", null, null) }
        } catch (e: IllegalStateException) {
            // Thrown when this app already has a pending request.
            reply { result.error("incompatible", null, null) }
        }
    }

    private fun failureCode(reason: Int): String = when (reason) {
        WifiManager.LocalOnlyHotspotCallback.ERROR_INCOMPATIBLE_MODE -> "incompatible"
        WifiManager.LocalOnlyHotspotCallback.ERROR_TETHERING_DISALLOWED -> "disallowed"
        WifiManager.LocalOnlyHotspotCallback.ERROR_NO_CHANNEL -> "no_channel"
        else -> "generic"
    }

    @TargetApi(Build.VERSION_CODES.O)
    @Suppress("DEPRECATION")
    private fun credentials(started: WifiManager.LocalOnlyHotspotReservation): Map<String, String?> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val config = started.softApConfiguration
            val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                config.wifiSsid?.toString()?.removeSurrounding("\"")
            } else {
                config.ssid
            }
            mapOf("ssid" to ssid, "password" to config.passphrase)
        } else {
            val config = started.wifiConfiguration
            mapOf(
                "ssid" to config?.SSID?.removeSurrounding("\""),
                "password" to config?.preSharedKey?.removeSurrounding("\""),
            )
        }
}
