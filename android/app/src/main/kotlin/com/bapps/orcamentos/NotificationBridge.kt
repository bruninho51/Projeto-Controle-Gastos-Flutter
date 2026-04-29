package com.bapps.orcamentos

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object NotificationBridge {
    private const val CHANNEL = "notification_bridge"
    private const val THROTTLE_MS = 500L
    private const val MAX_PENDING = 50

    private val mainHandler = Handler(Looper.getMainLooper())
    private val lock = Any()

    private var methodChannel: MethodChannel? = null
    private val pendingEvents = ArrayDeque<Map<String, Any>>()
    private var lastDispatchTime = 0L

    fun initialize(flutterEngine: FlutterEngine) {
        synchronized(lock) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            val toFlush = pendingEvents.toList()
            pendingEvents.clear()
            toFlush.forEach { dispatchToFlutter(it) }
        }
    }

    fun dispose() {
        synchronized(lock) {
            methodChannel = null
        }
    }

    fun sendNotification(data: Map<String, Any>) {
        synchronized(lock) {
            val now = System.currentTimeMillis()
            if (methodChannel != null) {
                if (now - lastDispatchTime < THROTTLE_MS) return
                lastDispatchTime = now
                dispatchToFlutter(data)
            } else {
                if (pendingEvents.size >= MAX_PENDING) pendingEvents.removeFirst()
                pendingEvents.addLast(data)
            }
        }
    }

    private fun dispatchToFlutter(data: Map<String, Any>) {
        val channel = methodChannel ?: return
        mainHandler.post {
            try {
                channel.invokeMethod("onNotification", data)
            } catch (e: Exception) {
                Log.e("NotificationBridge", "invokeMethod failed: ${e.message}")
            }
        }
    }
}
