import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAppLogo(),
                  const SizedBox(height: 40),
                  _buildWelcomeText(),
                  const SizedBox(height: 24),
                  _buildDescriptionText(),
                  const SizedBox(height: 40),
                  _buildGoogleSignInButton(authProvider),
                  const SizedBox(height: 30),
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.indigo.shade700,
          Colors.indigo.shade500,
        ],
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon.png',
        width: 120,
        height: 120,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Bem-vindo ao',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Orçamentos App',
          style: TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionText() {
    return const Text(
      'Gerencie seus orçamentos de forma simples e eficiente',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.white70,
        height: 1.5,
      ),
    );
  }

  Widget _buildGoogleSignInButton(AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleGoogleSignIn(authProvider),
        style: _googleButtonStyle(),
        child: _buildGoogleButtonContent(),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    await authProvider.signInWithGoogle();
  }

  ButtonStyle _googleButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0,
    );
  }

  Widget _buildGoogleButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/google.png',
          height: 28,
        ),
        const SizedBox(width: 12),
        const Text(
          'Entrar com Google',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return const Text(
      'Ao continuar, você concorda com nossos Termos e Política de Privacidade',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white54,
      ),
    );
  }
}