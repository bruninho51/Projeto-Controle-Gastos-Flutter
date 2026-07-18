import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encapsula a autenticação local (digital/rosto ou, como fallback, o
/// PIN/padrão do próprio aparelho) usada para trancar o app, além da
/// preferência do usuário de ligar/desligar esse bloqueio.
class BiometricService {
  static const _prefBloqueioAtivo = 'biometria_bloqueio_ativo';

  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Indica se o aparelho consegue autenticar o usuário de alguma forma —
  /// biometria cadastrada OU credencial de dispositivo (PIN/padrão/senha).
  /// Se retornar `false`, não faz sentido trancar (não haveria como destravar).
  Future<bool> get disponivel async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Exibe o prompt de autenticação. Retorna `true` só se o usuário provar a
  /// identidade. `biometricOnly: false` permite cair no PIN/padrão do aparelho
  /// quando não há biometria cadastrada, evitando que o usuário fique preso.
  Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para acessar o Orçamentos',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Preferência do usuário: se o app deve exigir bloqueio ao ser reaberto.
  /// Default `true` — mantém o comportamento seguro por padrão; o usuário
  /// pode desligar em Configurações › Segurança.
  Future<bool> get bloqueioAtivo async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefBloqueioAtivo) ?? true;
  }

  Future<void> setBloqueioAtivo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBloqueioAtivo, value);
  }
}
