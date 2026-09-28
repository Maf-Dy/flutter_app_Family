package com.mafdy.familygame

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keeps the app alive while it hosts a room: friends' phones talk to the server
 * running inside this app, so if Android stopped the app in the background (a
 * phone call, the power button, another app) the game would end for everyone.
 *
 * A foreground service with a "Hosting a game" notification tells Android the
 * app is doing something the person asked for. It also holds the CPU and Wi-Fi
 * awake with the screen off. Started when a room opens, stopped when it closes.
 */
class HostingService : Service() {
    private var cpu: PowerManager.WakeLock? = null
    private var wifi: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Hosting a game"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
        val notification = notification(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        holdLocks()
        // If Android has to kill it anyway, don't bring it back without the game.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        cpu?.takeIf { it.isHeld }?.release()
        wifi?.takeIf { it.isHeld }?.release()
        cpu = null
        wifi = null
        super.onDestroy()
    }

    /** The person swiped the app away from recent apps: the room is gone, so is this. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    private fun holdLocks() {
        if (cpu == null) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            cpu = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "FamilyGame:hosting").apply {
                setReferenceCounted(false)
                // A night of play, not forever: a room left open by mistake lets go by morning.
                acquire(MAX_HOLD_MS)
            }
        }
        if (wifi == null) {
            val manager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                WifiManager.WIFI_MODE_FULL_LOW_LATENCY
            } else {
                WifiManager.WIFI_MODE_FULL_HIGH_PERF
            }
            wifi = manager.createWifiLock(mode, "FamilyGame:hosting").apply {
                setReferenceCounted(false)
                acquire()
            }
        }
    }

    private fun notification(title: String, text: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, title, NotificationManager.IMPORTANCE_LOW).apply {
                    setShowBadge(false)
                },
            )
        }
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(R.drawable.ic_stat_hosting)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    companion object {
        const val CHANNEL = "family_game/hosting"
        private const val CHANNEL_ID = "hosting"
        private const val NOTIFICATION_ID = 8182
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val MAX_HOLD_MS = 6L * 60 * 60 * 1000

        fun start(context: Context, title: String, text: String) {
            val intent = Intent(context, HostingService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, HostingService::class.java))
        }
    }
}
