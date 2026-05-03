package com.bapps.orcamentos

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.bapps.orcamentos/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Verificações de estado ──────────────────────────

                    "isNotificationListenerEnabled" ->
                        result.success(isNotificationListenerEnabled())

                    "isBatteryOptimizationExempt" ->
                        result.success(isBatteryOptimizationExempt())

                    "isPostNotificationsGranted" ->
                        result.success(isPostNotificationsGranted())

                    "isServiceRunning" ->
                        result.success(MonitorForegroundService.isRunning)

                    // ── Solicitações de permissão ───────────────────────

                    "notificationListener" -> {
                        requestNotificationListenerAccess()
                        result.success(true)
                    }

                    "batteryOptimization" -> {
                        requestBatteryOptimizationExemption()
                        result.success(true)
                    }

                    "postNotifications" -> {
                        requestPostNotificationsPermission()
                        result.success(true)
                    }

                    // ── Serviço ─────────────────────────────────────────

                    "startService" -> {
                        startMonitorServiceSafe()
                        result.success(true)
                    }

                    "stopService" -> {
                        stopService(Intent(this, MonitorForegroundService::class.java))
                        result.success(true)
                    }

                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        NotificationBridge.dispose()
        super.onDestroy()
    }

    // ── Verificações ──────────────────────────────────────────────────────────

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )

        android.util.Log.d("NLCheck", "flat: '$flat'")
        android.util.Log.d("NLCheck", "packageName: '$packageName'")
        android.util.Log.d("NLCheck", "cn: '${ComponentName(this, NotificationListener::class.java).flattenToString()}'")

        if (flat.isNullOrBlank()) return false

        flat.split(":").forEach {
            android.util.Log.d("NLCheck", "entry: '$it'")
        }

        return flat.split(":").any { component ->
            runCatching {
                ComponentName.unflattenFromString(component) == ComponentName(this, NotificationListener::class.java)
            }.getOrDefault(false)
        }
    }

    private fun isBatteryOptimizationExempt(): Boolean {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun isPostNotificationsGranted(): Boolean {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.TIRAMISU) {
            return true // abaixo do Android 13 a permissão não existe
        }
        return checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    // ── Solicitações ──────────────────────────────────────────────────────────

    private fun requestNotificationListenerAccess() {
        startActivity(
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    private fun requestBatteryOptimizationExemption() {
        if (!isBatteryOptimizationExempt()) {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
            )
        }
    }

    private fun requestPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
        }
    }

    private fun openAppSettings() {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
        )
    }

    private fun startMonitorServiceSafe() {
        try {
            val intent = Intent(this, MonitorForegroundService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (_: Exception) {}
    }
}