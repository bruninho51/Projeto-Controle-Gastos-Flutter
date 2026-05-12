import 'package:flutter/services.dart';

class MonitorChannel {
  static const _channel = MethodChannel('com.bapps.orcamentos/monitor');

  // ── Verificações ──────────────────────────────────────

  static Future<bool> isNotificationListenerEnabled() async =>
      await _channel.invokeMethod<bool>('isNotificationListenerEnabled') ?? false;

  static Future<bool> isBatteryOptimizationExempt() async =>
      await _channel.invokeMethod<bool>('isBatteryOptimizationExempt') ?? false;

  static Future<bool> isPostNotificationsGranted() async =>
      await _channel.invokeMethod<bool>('isPostNotificationsGranted') ?? false;

  static Future<bool> isServiceRunning() async =>
      await _channel.invokeMethod<bool>('isServiceRunning') ?? false;

  // ── Permissões ────────────────────────────────────────

  static Future<void> requestNotificationListener() async =>
      await _channel.invokeMethod('notificationListener');

  static Future<void> requestBatteryOptimization() async =>
      await _channel.invokeMethod('batteryOptimization');

  static Future<void> requestPostNotifications() async =>
      await _channel.invokeMethod('postNotifications');

  static Future<void> openAppSettings() async =>
      await _channel.invokeMethod('openAppSettings');

  // ── Serviço ───────────────────────────────────────────

  static Future<void> startService() async =>
      await _channel.invokeMethod('startService');

  static Future<void> stopService() async =>
      await _channel.invokeMethod('stopService');
}