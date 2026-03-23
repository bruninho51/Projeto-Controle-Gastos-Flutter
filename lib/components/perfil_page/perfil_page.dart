import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _PerfilHeader(auth: auth),

          // ── Conteúdo ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      kIsWeb ? 32 : 20,
                      24,
                      kIsWeb ? 32 : 20,
                      40,
                    ),
                    child: Column(
                      children: [
                        // Card de informações do usuário
                        _InfoCard(auth: auth),
                        const SizedBox(height: 16),
                        // Card de ações
                        _ActionsCard(auth: auth),
                        const SizedBox(height: 32),
                        // Versão
                        Text(
                          'Orçamentos App • v1.0.0',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Header com avatar grande e nome do usuário
// ═══════════════════════════════════════════════════════════════════════════════
class _PerfilHeader extends StatelessWidget {
  final AuthProvider auth;
  const _PerfilHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, top + 20, 24, 32),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildAvatar(),
          ),
          const SizedBox(height: 16),

          // Nome
          Text(
            auth.user?.displayName ?? 'Usuário',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Email
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              auth.user?.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (auth.user?.photoURL != null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: Colors.indigo[100],
        backgroundImage: NetworkImage(auth.user!.photoURL!),
      );
    }
    return CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person_rounded, size: 52, color: Colors.white),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card de informações
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final AuthProvider auth;
  const _InfoCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_rounded,
            color: const Color(0xFF3949AB),
            label: 'Nome',
            value: auth.user?.displayName ?? 'Não informado',
            isFirst: true,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.email_rounded,
            color: const Color(0xFF1E88E5),
            label: 'E-mail',
            value: auth.user?.email ?? 'Não informado',
          ),
          _Divider(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card de ações
// ═══════════════════════════════════════════════════════════════════════════════
class _ActionsCard extends StatelessWidget {
  final AuthProvider auth;
  const _ActionsCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.logout_rounded,
            color: const Color(0xFFE53935),
            label: 'Sair da conta',
            onTap: auth.logout,
            isFirst: true,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─── Linha de informação ──────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isFirst ? 16 : 12,
        16,
        isLast ? 16 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1A1F36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de ação ────────────────────────────────────────────────────────────
class _ActionRow extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: widget.isFirst ? const Radius.circular(18) : Radius.zero,
      bottom: widget.isLast ? const Radius.circular(18) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        splashColor: widget.color.withOpacity(0.08),
        highlightColor: widget.color.withOpacity(0.04),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            widget.isFirst ? 16 : 12,
            16,
            widget.isLast ? 16 : 12,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Divisor interno do card ──────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(height: 1, color: Colors.grey[100]),
    );
  }
}