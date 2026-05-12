package com.bapps.orcamentos.monitor

import android.content.Context

object MonitorPrefs {
    private const val PREFS_NAME        = "monitor_prefs"
    private const val KEY_SERVICE_ENABLED = "service_enabled"

    fun isServiceEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getBoolean(KEY_SERVICE_ENABLED, false)

    fun setServiceEnabled(context: Context, enabled: Boolean) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_SERVICE_ENABLED, enabled).apply()
}