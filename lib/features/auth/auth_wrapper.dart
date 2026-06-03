import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/auth/pages/login_page.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/splash/pages/splash_screen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.home,
  });

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return switch (auth) {
      AuthState(isLoading: true) => const SplashScreen(),
      AuthState(isLoggedIn: false) => const LoginPage(),
      _ => home,
    };
  }
}