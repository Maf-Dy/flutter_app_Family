package com.mafdy.familygame

import android.annotation.TargetApi
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.SoftApConfiguration
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

/**
 * Starts Android's local-only hotspot so friends can join the room without a router,
 * reports the phone's Wi-Fi address, and holds the multicast lock while the app
 * listens for rooms (without it many phones drop Wi-Fi broadcasts to save power).
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
    private val connectivity =
        context.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private val multicast = wifi.createMulticastLock("family_game_rooms").apply { setReferenceCounted(false) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sdkInt" -> result.success(Build.VERSION.SDK_INT)
            "wifiAddress" -> result.success(wifiAddress())
            "start" -> start(result)
            "lockMulticast" -> {
                multicast.acquire()
                result.success(null)
            }
            "unlockMulticast" -> {
                if (multicast.isHeld) multicast.release()
                result.success(null)
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** The activity is going away: end the hotspot and stop listening for rooms. */
    fun dispose() {
        stop()
        if (multicast.isHeld) multicast.release()
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
                    // Stopped before it ever started: answer, or Dart waits forever.
                    reply { result.error("generic", null, null) }
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
            // Newer phones may run the hotspot as WPA3-only, which needs "SAE" in the Wi-Fi QR code.
            val security = when (config.securityType) {
                SoftApConfiguration.SECURITY_TYPE_OPEN -> "open"
                SoftApConfiguration.SECURITY_TYPE_WPA3_SAE -> "wpa3"
                else -> "wpa"
            }
            mapOf("ssid" to ssid, "password" to config.passphrase, "security" to security)
        } else {
            val config = started.wifiConfiguration
            mapOf(
                "ssid" to config?.SSID?.removeSurrounding("\""),
                "password" to config?.preSharedKey?.removeSurrounding("\""),
                "security" to "wpa",
            )
        }

    /**
     * This phone's IPv4 address on the Wi-Fi (or Ethernet) network it is connected
     * to, straight from Android, or null when it is not connected to one.
     */
    @Suppress("DEPRECATION")
    private fun wifiAddress(): String? {
        for (network in connectivity.allNetworks) {
            val capabilities = connectivity.getNetworkCapabilities(network) ?: continue
            val onWifi = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
            if (!onWifi) continue
            val link = connectivity.getLinkProperties(network) ?: continue
            val address = link.linkAddresses.firstOrNull { it.address is Inet4Address } ?: continue
            return address.address.hostAddress
        }
        return null
    }
}
