import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // <-- Adiciona este import
import 'components/common/main_app_scaffold.dart';
import 'components/login_page/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase com as opções corretas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadCurrentUser(),
      child: MaterialApp(
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
    final auth = Provider.of<AuthProvider>(context);

    if (auth.user == null) {
      return const LoginPage();
    }

    if (auth.apiToken.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MainAppScaffold();
  }
}
