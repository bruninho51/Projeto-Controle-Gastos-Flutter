package com.bapps.orcamentos

import android.os.Handler
import android.os.HandlerThread
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {

    private lateinit var workerThread: HandlerThread
    private lateinit var workerHandler: Handler

    companion object {
        private const val TAG = "NOTIF"

        private val ALLOWED_PACKAGES = setOf(
            "com.nu.production",
            "br.com.intermedium",
            "br.gov.caixa.tem",
            "com.bradesco",
            "com.mand.notitest"
        )
    }

    override fun onCreate() {
        super.onCreate()
        workerThread = HandlerThread("NotificationWorker").also { it.start() }
        workerHandler = Handler(workerThread.looper)
    }

    override fun onDestroy() {
        workerThread.quitSafely()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (packageName !in ALLOWED_PACKAGES) return

        val notification = sbn.notification
        val postTime = sbn.postTime

        workerHandler.post {
            val extras = notification.extras

            val title = extras.getCharSequence("android.title")?.toString().orEmpty()
            val content = extras.getCharSequence("android.text")?.toString().orEmpty()

            // ✅ log só do que interessa
            Log.d(TAG, "[$packageName] $title - $content")

            NotificationBridge.sendNotification(
                mapOf(
                    "package" to packageName,
                    "title" to title,
                    "content" to content,
                    "timestamp" to postTime
                )
            )
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) = Unit
}