import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/shared/api_models.dart';

import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Header navbar com botão ⋮
// ═══════════════════════════════════════════════════════════════════════════════
class FixosHeader extends StatelessWidget {
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onFiltros;
  final VoidCallback onBack;
  final VoidCallback onCopiar;
  final bool temFiltroAtivo;
  final AuthState auth;
  final Future<List<GastoFixoResponseDto>> gastosFuture;
  final List<GastoFixoResponseDto> Function(List<GastoFixoResponseDto>) filtrar;

  const FixosHeader({
    required this.isRefreshing, required this.refreshCtrl,
    required this.onRefresh, required this.onFiltros,
    required this.onBack, required this.onCopiar,
    required this.temFiltroAtivo, required this.auth,
    required this.gastosFuture, required this.filtrar,
  });

  Widget _buildAvatar() {
    if (auth.user?.photoURL != null) {
      return ClipOval(
        child: Image.network(auth.user!.photoURL!,
            width: 38, height: 38, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar()),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
  );

  void _showMenu(BuildContext context, GlobalKey key) {
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showMenu<String>(
      context: context,
      color: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: RelativeRect.fromLTRB(
        offset.dx,                           // alinhado à esquerda do botão
        offset.dy + size.height + 4,         // logo abaixo do botão
        screenWidth - (offset.dx + size.width), // distância da borda direita
        screenHeight - (offset.dy + size.height + 4), // distância da borda inferior
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copiar',
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.copy_all_rounded, color: Color(0xFF1A237E), size: 16)),
              const SizedBox(width: 12),
              const Text('Copiar do Orçamento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1F36))),
            ]),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'copiar') onCopiar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final menuKey = GlobalKey();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Linha 1 ────────────────────────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (canPop) ...[
            HeaderButton(onTap: onBack, tooltip: 'Voltar', isSquare: true,
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 12),
          ],
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gastos Fixos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            Text('Planejamento de despesas', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ])),
          const SizedBox(width: 10),
          _buildAvatar(),
        ]),

        const SizedBox(height: 16),

        // ── Total gasto ───────────────────────────────────────────────────────
        FutureBuilder<List<GastoFixoResponseDto>>(
          future: gastosFuture,
          builder: (context, snapshot) {
            final filtrados = filtrar(snapshot.data ?? []);
            final totalGasto = filtrados.fold<double>(
                0, (s, g) => s + (double.tryParse(g.valor ?? '0') ?? 0));
            final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Container(width: 30, height: 30,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.payments_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 10),
                Text('Total gasto', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(fmt.format(totalGasto),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ]),
            );
          },
        ),

        const SizedBox(height: 16),

        // ── Linha 2 ────────────────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
              const SizedBox(width: 7),
              const Text('Planejamentos', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),

          // Filtros
          Stack(children: [
            HeaderButton(onTap: onFiltros, tooltip: 'Filtros',
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Filtros', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
            if (temFiltroAtivo)
              Positioned(top: 2, right: 2,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFD740), shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 8),

          // Refresh
          HeaderButton(onTap: onRefresh, tooltip: 'Recarregar', isSquare: true,
              child: RotationTransition(
                turns: refreshCtrl,
                child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(isRefreshing ? 1.0 : 0.9), size: 18),
              )),
          const SizedBox(width: 8),

          // 3 pontinhos
          HeaderButton(
            key: menuKey,
            onTap: () => _showMenu(context, menuKey),
            tooltip: 'Mais opções',
            isSquare: true,
            child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
          ),
        ]),
      ]),
    );
  }
}

// ─── Botão glassmorphism ──────────────────────────────────────────────────────
class HeaderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool isSquare;

  const HeaderButton({super.key, required this.child, required this.onTap, required this.tooltip, this.isSquare = false});

  @override
  State<HeaderButton> createState() => HeaderButtonState();
}

class HeaderButtonState extends State<HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(horizontal: widget.isSquare ? 10 : 14, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
