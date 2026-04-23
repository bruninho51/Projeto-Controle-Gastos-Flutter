import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orcamentos_app/shared/auth_service.dart';
import 'package:orcamentos_app/shared/push_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'firebase_options.dart';
import 'components/common/main_app_scaffold.dart';
import 'components/login_page/login_page.dart';

import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/shared/api_service.dart';

// 🔐 infra
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _webClientId =
    '1004439512234-mqqb1622hk1f9tlomi5r83gmh14b9bno.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();

  runApp(const MyApp());
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.requestPermission();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: const _AppView(),
    );
  }
}

List<SingleChildWidget> _buildProviders() {
  return [
    // ================= INFRA =================

    Provider(
      create: (_) => AuthService(
        auth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(
          clientId: kIsWeb ? _webClientId : null,
        ),
      ),
    ),

    Provider(create: (_) => PushService()),

    // ================= API =================

    Provider<ApiService>(
      create: (context) => ApiService(),
    ),

    // ================= AUTH =================

    ChangeNotifierProvider(
      create: (context) => AuthState(
        context.read<AuthService>(),
        context.read<ApiService>(),
        context.read<PushService>(),
      ),
    ),
  ];
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.isLoading) {
      return const _Loading();
    }

    if (!auth.isLoggedIn) {
      return const LoginPage();
    }

    return const MainAppScaffold();
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}