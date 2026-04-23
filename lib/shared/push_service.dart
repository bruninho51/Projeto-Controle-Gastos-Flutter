import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class PushService {
  Future<void> registerDevice(ApiService api) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await api.upsertTokenDispositivo(
      TokenDispositivoUpsertDto(
        token: token,
        plataforma: 'android',
      ),
    );
  }
}