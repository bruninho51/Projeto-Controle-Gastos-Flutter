package com.bapps.orcamentos

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat

class MonitorForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "notification_monitor_channel"
        private const val NOTIFICATION_ID = 1001

        @Volatile
        var isRunning = false
            private set
    }

    private val handler = Handler(Looper.getMainLooper())

    private var startedForeground = false

    private val watchdogRunnable = object : Runnable {
        override fun run() {

            if (!isServiceAllowed()) {
                stopSelf()
                return
            }

            if (isRunning) {
                ensureNotificationVisible()
                handler.postDelayed(this, 5000)
            }
        }
    }

    // ─────────────────────────────
    // ENTRY POINT SAFETY
    // ─────────────────────────────

    override fun onCreate() {
        super.onCreate()

        if (!isServiceAllowed()) {
            stopSelf()
            return
        }

        createNotificationChannel()

        if (!startAsForegroundSafe()) {
            stopSelf()
            return
        }

        isRunning = true
        handler.post(watchdogRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        if (!isServiceAllowed()) {
            stopSelf()
            return START_NOT_STICKY
        }

        if (!startedForeground) {
            if (!startAsForegroundSafe()) {
                stopSelf()
                return START_NOT_STICKY
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(watchdogRunnable)
        startedForeground = false
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        isRunning = false
        handler.removeCallbacks(watchdogRunnable)
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    // ─────────────────────────────
    // RULE ENGINE (IMPORTANTE)
    // ─────────────────────────────

    private fun isServiceAllowed(): Boolean {

        // Android 13+ notification permission
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED

            if (!granted) return false
        }

        return true
    }

    // ─────────────────────────────
    // FOREGROUND START (SAFE)
    // ─────────────────────────────

    private fun startAsForegroundSafe(): Boolean {
        return try {

            val notification = buildNotification()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            startedForeground = true
            true

        } catch (e: Exception) {
            false
        }
    }

    // ─────────────────────────────
    // WATCHDOG
    // ─────────────────────────────

    private fun ensureNotificationVisible() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val activeNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            manager.activeNotifications
        } else {
            emptyArray()
        }

        val exists = activeNotifications.any { it.id == NOTIFICATION_ID }

        if (!exists && startedForeground) {
            startAsForegroundSafe()
        }
    }

    // ─────────────────────────────
    // CHANNEL
    // ─────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val channel = NotificationChannel(
                CHANNEL_ID,
                "Notification Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    // ─────────────────────────────
    // NOTIFICATION
    // ─────────────────────────────

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Orçamentos App")
            .setContentText("Monitor ativo (quando permitido)")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}