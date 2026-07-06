package com.bapps.orcamentos.monitor

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.bapps.orcamentos.permissions.AutostartSettingsHelper
import com.bapps.orcamentos.permissions.PermissionChecker

class MonitorFlutterCallReceiver(
    private val activity: android.app.Activity
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.bapps.orcamentos/monitor"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // ── Verificações ───────────────────────────────────

            "isNotificationListenerEnabled" ->
                result.success(PermissionChecker.isNotificationListenerEnabled(activity))

            "isBatteryOptimizationExempt" ->
                result.success(PermissionChecker.isBatteryOptimizationExempt(activity))

            "isPostNotificationsGranted" ->
                result.success(PermissionChecker.isPostNotificationsGranted(activity))

            "isServiceRunning" ->
                result.success(MonitorForegroundService.isRunning)

            "openAutostartSettings" ->
                result.success(AutostartSettingsHelper.open(activity))

            // ── Solicitações de permissão ───────────────────────

            "notificationListener" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(true)
            }

            "batteryOptimization" -> {
                if (!PermissionChecker.isBatteryOptimizationExempt(activity)) {
                    activity.startActivity(
                        Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            .apply {
                                data = Uri.parse("package:${activity.packageName}")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                    )
                }
                result.success(true)
            }

            "postNotifications" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    activity.requestPermissions(
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001
                    )
                }
                result.success(true)
            }

            // ── Serviço ─────────────────────────────────────────

            "startService" -> {
                MonitorPrefs.setServiceEnabled(activity, true)
                startServiceSafe()
                result.success(true)
            }

            "stopService" -> {
                MonitorPrefs.setServiceEnabled(activity, false)
                activity.stopService(Intent(activity, MonitorForegroundService::class.java))
                result.success(true)
            }

            "openAppSettings" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .apply {
                            data = Uri.parse("package:${activity.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                )
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    fun startServiceSafe() {
        try {
            val intent = Intent(activity, MonitorForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                activity.startForegroundService(intent)
            } else {
                activity.startService(intent)
            }
        } catch (e: Exception) {
            Log.e("MonitorChannelHandler", "Erro ao iniciar serviço", e)
        }
    }
}