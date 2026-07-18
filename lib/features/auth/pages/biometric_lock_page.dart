import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Tela exibida quando a sessão foi restaurada silenciosamente (método A) e o
/// app aguarda confirmação biométrica. Dispara o prompt automaticamente ao
/// abrir e oferece um botão para tentar de novo (caso o usuário cancele) ou
/// sair da conta.
class BiometricLockPage extends StatefulWidget {
  const BiometricLockPage({super.key});

  @override
  State<BiometricLockPage> createState() => _BiometricLockPageState();
}

class _BiometricLockPageState extends State<BiometricLockPage> {
  static const _dark = Color(0xFF1A237E);
  static const _mid = Color(0xFF283593);

  bool _autenticando = false;

  @override
  void initState() {
    super.initState();
    // Dispara o prompt assim que a tela monta.
    WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquear());
  }

  Future<void> _desbloquear() async {
    if (_autenticando) return;
    setState(() => _autenticando = true);
    await context.read<AuthState>().desbloquear();
    if (mounted) setState(() => _autenticando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'App bloqueado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirme sua identidade para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _autenticando ? null : _desbloquear,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Desbloquear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _mid,
                    disabledBackgroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _autenticando
                    ? null
                    : () => context.read<AuthState>().logout(),
                child: const Text(
                  'Sair da conta',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
