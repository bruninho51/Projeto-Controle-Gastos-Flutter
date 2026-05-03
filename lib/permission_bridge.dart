import 'package:flutter/services.dart';

class PermissionBridge {
  static const _channel =
  MethodChannel('com.bapps.orcamentos/permissions');

  static Future<void> batteryOptimization() async {
    await _channel.invokeMethod('batteryOptimization');
  }

  static Future<void> notificationListener() async {
    await _channel.invokeMethod('notificationListener');
  }

  static Future<void> openAppSettings() async {
    await _channel.invokeMethod('openAppSettings');
  }
}