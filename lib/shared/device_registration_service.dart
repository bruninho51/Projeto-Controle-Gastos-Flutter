import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class DeviceRegistrationService {
  final ApiService api;

  static const _keyTokenId = 'token_dispositivo_id';
  static const _vapidKey   = 'BMmAUVV7hX15wTurZfCdgKkJzt8KLeyQThsQTnKu6wUpceEIDGJxwrCy4jupeVaGKtjaqYv57ZvjGijUgk0O6o8';

  DeviceRegistrationService(this.api);

  String get _plataforma {
    if (kIsWeb)           return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS)     return 'ios';
    if (Platform.isMacOS)   return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux)   return 'linux';
    return 'unknown';
  }

  String? get _vapidKeyOrNull => kIsWeb ? _vapidKey : null;

  Future<void> registerDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final notificacoesAtivas = prefs.getBool('notificacoes_ativas') ?? false;
    if (!notificacoesAtivas) return;

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: _vapidKeyOrNull,
    );
    if (token == null) return;

    final response = await api.upsertTokenDispositivo(
      TokenDispositivoUpsertDto(
        token: token,
        plataforma: _plataforma,
      ),
    );

    await prefs.setInt(_keyTokenId, response.id);
  }

  Future<void> unregisterDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id    = prefs.getInt(_keyTokenId);
    if (id == null) return;

    await api.deleteTokenDispositivo(id);
    await prefs.remove(_keyTokenId);
  }
}