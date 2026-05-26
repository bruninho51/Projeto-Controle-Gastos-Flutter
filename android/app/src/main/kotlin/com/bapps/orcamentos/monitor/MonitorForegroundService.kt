package com.bapps.orcamentos.monitor

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.*
import androidx.core.app.NotificationCompat
import com.bapps.orcamentos.R

class MonitorForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID      = "notification_monitor_channel"
        private const val NOTIFICATION_ID = 1001

        @Volatile
        var isRunning = false
            private set
    }

    private val handler = Handler(Looper.getMainLooper())

    // ─────────────────────────────
    // LIFECYCLE
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
        handler.postDelayed(watchdogRunnable, 5_000)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isRunning) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        teardown()
        super.onDestroy()
    }

    // onTaskRemoved REMOVIDO — fechar o app pelo recentes não derruba o serviço

    // ─────────────────────────────
    // TEARDOWN
    // ─────────────────────────────

    private fun teardown() {
        isRunning = false
        handler.removeCallbacks(watchdogRunnable)
    }

    // ─────────────────────────────
    // WATCHDOG
    // ─────────────────────────────

    private val watchdogRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return

            if (!isServiceAllowed()) {
                stopSelf()
                return
            }

            ensureNotificationVisible()
            handler.postDelayed(this, 5_000)
        }
    }

    // ─────────────────────────────
    // PERMISSÃO MÍNIMA
    // ─────────────────────────────

    private fun isServiceAllowed(): Boolean {
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

            true
        } catch (e: Exception) {
            false
        }
    }

    // ─────────────────────────────
    // WATCHDOG — checar notificação
    // ─────────────────────────────

    private fun ensureNotificationVisible() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val exists  = manager.activeNotifications.any { it.id == NOTIFICATION_ID }

        if (!exists) {
            startAsForegroundSafe()
        }
    }

    // ─────────────────────────────
    // CANAL DE NOTIFICAÇÃO
    // ─────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Monitor de notificações",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description          = "Serviço de captura de gastos automáticos"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    // ─────────────────────────────
    // NOTIFICAÇÃO
    // ─────────────────────────────

    private fun buildNotification(): Notification {
        val pendingIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.let { launchIntent ->
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                PendingIntent.getActivity(
                    this, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Orçamentos")
            .setContentText("Capturando notificações bancárias em segundo plano")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }
}