import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/shared/biometric_service.dart';
import 'package:provider/provider.dart';

class SegurancaPage extends StatefulWidget {
  const SegurancaPage({super.key});

  @override
  State<SegurancaPage> createState() => _SegurancaPageState();
}

class _SegurancaPageState extends State<SegurancaPage> {
  static const _mid = Color(0xFF283593);
  static const _light = Color(0xFF3949AB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  bool _loading = true;
  bool _disponivel = false;
  bool _bloqueioAtivo = false;

  BiometricService get _biometric =>
      Provider.of<BiometricService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final disponivel = await _biometric.disponivel;
    final ativo = await _biometric.bloqueioAtivo;
    if (!mounted) return;
    setState(() {
      _disponivel = disponivel;
      _bloqueioAtivo = ativo;
      _loading = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      if (!_disponivel) {
        _showBlockedSnack();
        return;
      }
      // Confirma que o usuário consegue autenticar antes de ligar o bloqueio,
      // evitando que ele se tranque para fora do app.
      if (!await _biometric.autenticar()) return;
    }

    await _biometric.setBloqueioAtivo(value);
    if (!mounted) return;
    setState(() => _bloqueioAtivo = value);
  }

  void _showBlockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Configure uma biometria ou PIN/padrão nas configurações do aparelho.',
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: SharedAppBar(
        title: 'Segurança',
        subtitle: 'Proteja o acesso ao app',
        mainIcon: Icons.shield_outlined,
        gradientColors: _gradientColors,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                _buildSectionLabel('Bloqueio do app'),
                _buildLockCard(),
                if (!_disponivel) ...[
                  const SizedBox(height: 12),
                  _buildBlockedBanner(),
                ],
              ],
            ),
    );
  }

  // ── Seção bloqueio ────────────────────────────────────

  Widget _buildLockCard() {
    return Opacity(
      opacity: _disponivel ? 1.0 : 0.5,
      child: _SecurityCard(
        children: [
          _SecurityTile(
            icon: _bloqueioAtivo
                ? Icons.lock_rounded
                : Icons.lock_open_rounded,
            iconColor: _bloqueioAtivo ? _light : Colors.grey,
            title: 'Biometria / PIN',
            subtitle: _bloqueioAtivo
                ? 'O app pede sua identidade ao ser reaberto'
                : 'O bloqueio ao reabrir o app está desativado',
            action: Switch(
              value: _bloqueioAtivo,
              onChanged: (_disponivel || _bloqueioAtivo) ? _onToggle : null,
              activeThumbColor: Colors.white,
              activeTrackColor: _mid,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner de bloqueio ────────────────────────────────

  Widget _buildBlockedBanner() {
    const color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Configure uma biometria ou um PIN/padrão nas configurações do '
              'aparelho para poder ativar o bloqueio.',
              style: TextStyle(fontSize: 12, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Label de seção ────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final List<Widget> children;
  const _SecurityCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget action;

  const _SecurityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
