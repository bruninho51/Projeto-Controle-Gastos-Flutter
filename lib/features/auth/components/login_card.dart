import 'package:flutter/material.dart';

class LoginCard extends StatelessWidget {
  final VoidCallback onSignIn;
  final bool isLoading;

  const LoginCard({
    super.key,
    required this.onSignIn,
    required this.isLoading,
  });

  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _accent = Color(0xFF7986CB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _dark.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Entrar na sua conta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _mid,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use sua conta Google para continuar',
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
          const SizedBox(height: 28),
          _buildGoogleSignInButton(),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildTermsText(),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _mid,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/google.png', height: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Entrar com Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.black12, thickness: 0.8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'acesso seguro',
            style: TextStyle(fontSize: 11, color: Colors.black26),
          ),
        ),
        Expanded(child: Divider(color: Colors.black12, thickness: 0.8)),
      ],
    );
  }

  Widget _buildTermsText() {
    return const Text(
      'Ao continuar, você concorda com nossos\nTermos e Política de Privacidade',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: Colors.black38,
        height: 1.6,
      ),
    );
  }
}
