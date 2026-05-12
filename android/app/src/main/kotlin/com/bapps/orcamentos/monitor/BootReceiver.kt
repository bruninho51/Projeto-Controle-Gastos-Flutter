package com.bapps.orcamentos.monitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.bapps.orcamentos.permissions.PermissionChecker

class BootReceiver : BroadcastReceiver() {
    private val TAG = "BootReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        if (!MonitorPrefs.isServiceEnabled(context)) {
            Log.d(TAG, "Boot: service disabled by user")
            return
        }

        if (!PermissionChecker.hasAllPermissions(context)) {
            Log.d(TAG, "Boot: permissions missing")
            return
        }

        Log.d(TAG, "Boot: starting foreground service")
        val serviceIntent = Intent(context, MonitorForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}