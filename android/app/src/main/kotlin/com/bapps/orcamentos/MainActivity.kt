package com.bapps.orcamentos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.bapps.orcamentos.monitor.MonitorFlutterCallReceiver
import com.bapps.orcamentos.monitor.MonitorForegroundService
import com.bapps.orcamentos.monitor.MonitorPrefs
import com.bapps.orcamentos.notifications.NotificationBridge
import com.bapps.orcamentos.notificacoes.NotificacoesFlutterCallReceiver
import com.bapps.orcamentos.permissions.PermissionChecker

class MainActivity : FlutterActivity() {

    private lateinit var monitorHandler: MonitorFlutterCallReceiver

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        monitorHandler = MonitorFlutterCallReceiver(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MonitorFlutterCallReceiver.CHANNEL)
            .setMethodCallHandler(monitorHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NotificacoesFlutterCallReceiver.CHANNEL)
            .setMethodCallHandler(NotificacoesFlutterCallReceiver(this))
        NotificationBridge.initialize(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        if (MonitorPrefs.isServiceEnabled(this) &&
            PermissionChecker.hasAllPermissions(this) &&
            !MonitorForegroundService.isRunning
        ) {
            monitorHandler.startServiceSafe()
        }
    }

    override fun onDestroy() {
        NotificationBridge.dispose()
        super.onDestroy()
    }
}