package com.bapps.orcamentos

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.bapps.orcamentos/permissions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        //NotificationBridge.initialize(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    // ─────────────────────
                    // START SERVICE (SAFE)
                    // ─────────────────────
                    "startMonitorService" -> {
                        startMonitorServiceSafe()
                        result.success(true)
                    }

                    "batteryOptimization" -> {
                        requestBatteryOptimizationExemption()
                        result.success(true)
                    }

                    "notificationListener" -> {
                        requestNotificationListenerAccess()
                        result.success(true)
                    }

                    "postNotifications" -> {
                        requestPostNotificationsPermission()
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

    // ─────────────────────────────
    // SAFE SERVICE START
    // ─────────────────────────────

    private fun startMonitorServiceSafe() {
        try {
            val intent = Intent(this, MonitorForegroundService::class.java)

            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }

        } catch (e: Exception) {
            // não crasha app
        }
    }

    // ─────────────────────────────
    // PERMISSIONS
    // ─────────────────────────────

    private fun requestNotificationListenerAccess() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun requestBatteryOptimizationExemption() {
        val pm = getSystemService(POWER_SERVICE) as PowerManager

        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    private fun requestPostNotificationsPermission() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                1001
            )
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}