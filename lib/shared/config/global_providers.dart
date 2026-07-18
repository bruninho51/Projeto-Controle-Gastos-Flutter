import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/notifications/regex_patterns/repositories/padrao_regex_notificacao_repository.dart';
import 'package:orcamentos_app/features/notifications/services/notification_processing_service.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/shared/auth_service.dart';
import 'package:orcamentos_app/shared/config/app_config.dart';
import 'package:orcamentos_app/shared/device_registration_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> globalProviders() {
  return [
    Provider<ApiService>(
      create: (_) => ApiService(),
    ),
    Provider<AuthService>(
      create: (_) => AuthService(
        auth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(
          clientId: kIsWeb ? AppConfig.webClientId : null,
        ),
      ),
    ),
    Provider<DeviceRegistrationService>(
      create: (ctx) => DeviceRegistrationService(ctx.read<ApiService>()),
    ),
    Provider<PadraoRegexNotificacaoRepository>(
      create: (ctx) => PadraoRegexNotificacaoRepository(ctx.read<ApiService>()),
    ),
    Provider<NotificationProcessingService>(
      create: (ctx) => NotificationProcessingService(
        ctx.read<PadraoRegexNotificacaoRepository>(),
      ),
    ),
    ChangeNotifierProvider<AuthState>(
      create: (ctx) {
        final authState = AuthState(
          ctx.read<AuthService>(),
          ctx.read<ApiService>(),
        );
        
        // Após autenticar, registra o dispositivo no backend para habilitar
        // o recebimento de notificações push.
        authState.addPostAuthAction(
          ctx.read<DeviceRegistrationService>().registerDevice,
        );

        if (!kIsWeb) {
          // Inicializa o processamento de notificações apenas em plataformas nativas,
          // registrando listeners e tratando notificações pendentes.
          authState.addPostAuthAction(
            ctx.read<NotificationProcessingService>().initialize,
          );
        }

        return authState;
      },
    ),
  ];
}