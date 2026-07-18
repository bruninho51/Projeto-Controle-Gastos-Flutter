import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Encapsula a autenticação local (digital/rosto ou, como fallback, o
/// PIN/padrão do próprio aparelho) usada para trancar o app.
class BiometricService {
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
}
