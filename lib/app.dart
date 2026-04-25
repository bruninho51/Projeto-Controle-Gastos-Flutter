import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orcamentos_app/components/common/main_app_scaffold.dart';
import 'package:orcamentos_app/features/auth/auth_wrapper.dart';
import 'package:orcamentos_app/shared/config/global_providers.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: globalProviders(),
      child: MaterialApp(
        title: 'Orçamentos App',
        theme: ThemeData(primarySwatch: Colors.blue),
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
        home: const AuthWrapper(home: MainAppScaffold()),
      ),
    );
  }
}