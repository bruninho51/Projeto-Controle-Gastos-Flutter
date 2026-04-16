import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'components/common/main_app_scaffold.dart';
import 'components/login_page/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções corretas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        // AuthProvider precisa do ApiService para buscar o token
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            ApiService(tokenProvider: () => ''),
          )..loadCurrentUser(),
        ),
        // ProxyProvider atualiza o ApiService sempre que o token muda
        ProxyProvider<AuthProvider, ApiService>(
          update: (_, auth, __) => ApiService(
            tokenProvider: () => auth.apiToken,
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: 'Orçamentos App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, dynamic>((a) => a.user);
    final token = context.select<AuthProvider, String>((a) => a.apiToken);
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const LoginPage();
    }

    if (token.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MainAppScaffold();
  }
}
