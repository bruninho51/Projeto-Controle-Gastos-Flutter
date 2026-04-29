package com.bapps.orcamentos

import android.app.*
import android.content.Context
import android.content.Intent
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

    private val watchdogRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                ensureNotificationVisible()
                handler.postDelayed(this, 5000) // 🔁 verifica a cada 5s
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true

        createNotificationChannel()
        startAsForeground()

        // 🔥 inicia watchdog
        handler.post(watchdogRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacks(watchdogRunnable)

        // 🔥 tenta reviver
        val restartIntent = Intent(applicationContext, MonitorForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartIntent)
        } else {
            applicationContext.startService(restartIntent)
        }

        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        val restartIntent = Intent(applicationContext, MonitorForegroundService::class.java)
        restartIntent.setPackage(packageName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(restartIntent)
        } else {
            applicationContext.startService(restartIntent)
        }

        super.onTaskRemoved(rootIntent)
    }

    private fun startAsForeground() {
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
    }

    private fun ensureNotificationVisible() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val activeNotifications = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            manager.activeNotifications
        } else {
            emptyArray()
        }

        val exists = activeNotifications.any { it.id == NOTIFICATION_ID }

        if (!exists) {
            // 🔥 recria a notificação se o usuário deu swipe
            startAsForeground()
        }
    }

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

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Orçamentos App")
            .setContentText("Monitorando notificações para registrar gastos")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}