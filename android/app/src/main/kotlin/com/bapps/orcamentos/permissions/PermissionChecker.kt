package com.bapps.orcamentos.permissions

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.bapps.orcamentos.notifications.NotificationListener

object PermissionChecker {

    fun isNotificationListenerEnabled(context: Context): Boolean {
        val flat = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        )
        if (flat.isNullOrBlank()) return false
        return flat.split(":").any { component ->
            runCatching {
                ComponentName.unflattenFromString(component) ==
                        ComponentName(context, NotificationListener::class.java)
            }.getOrDefault(false)
        }
    }

    fun isBatteryOptimizationExempt(context: Context): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun isPostNotificationsGranted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
    }

    fun hasAllPermissions(context: Context): Boolean {
        return isNotificationListenerEnabled(context) &&
                isBatteryOptimizationExempt(context) &&
                isPostNotificationsGranted(context)
    }
}