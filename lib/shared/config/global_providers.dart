import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
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
    ChangeNotifierProvider<AuthState>(
      create: (ctx) => AuthState(
        ctx.read<AuthService>(),
        ctx.read<ApiService>(),
      )..onAfterAuth(ctx.read<DeviceRegistrationService>().registerDevice),
    ),
  ];
}