import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../dashboard_page/dashboard_page.dart';
import '../perfil_page/perfil_page.dart';
import 'package:orcamentos_app/features/config/pages/configuracoes_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;
  bool _railExtended = true;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', page: DashboardPage()),
    NavigationItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Orçamentos', page: OrcamentosPage()),
    NavigationItem(icon: Icons.savings_outlined, activeIcon: Icons.savings_rounded, label: 'Investimentos', page: InvestimentosPage()),
    NavigationItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil', page: PerfilPage()),
    NavigationItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Configurações', page: ConfiguracoesPage()),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    final bool useRail = isWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Row(
        children: [
          if (useRail) _buildNavigationRail(context),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _navigationItems.map((item) => item.page).toList(),
            ),
          ),
        ],
      ),
      // Bottom nav flutuante — só no mobile
      bottomNavigationBar: useRail ? null : _buildFloatingBottomNav(),
    );
  }

  // ─── Navigation Rail (web) ───────────────────────────────────────────────
  Widget _buildNavigationRail(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: _railExtended ? 220 : 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              _railExtended ? 20 : 16,
              MediaQuery.of(context).padding.top + 20,
              _railExtended ? 20 : 16,
              24,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                  ),
                ),
                if (_railExtended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orçamentos',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                        ),
                        Text('App', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Itens de navegação ───────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: _navigationItems.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final selected = i == _currentIndex;
                  return _RailItem(
                    item: item,
                    selected: selected,
                    extended: _railExtended,
                    onTap: () => setState(() => _currentIndex = i),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Rodapé: colapsar + sair ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + 20),
            child: Column(
              children: [
                // Divisor
                Container(height: 1, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.only(bottom: 12)),

                // Botão colapsar
                _RailFooterButton(
                  extended: _railExtended,
                  icon: _railExtended ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  label: 'Recolher',
                  onTap: () => setState(() => _railExtended = !_railExtended),
                ),
                const SizedBox(height: 6),
                // Botão sair
                _RailFooterButton(
                  extended: _railExtended,
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  onTap: auth.logout,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Nav Flutuante (mobile) ───────────────────────────────────────
  Widget _buildFloatingBottomNav() {
    return SafeArea(
      // SafeArea garante que o nav nunca cobre conteúdo do sistema
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: _navigationItems.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == _currentIndex;
              return Expanded(
                child: _BottomNavItem(
                  item: item,
                  selected: selected,
                  onTap: () => setState(() => _currentIndex = i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item do Navigation Rail
// ═══════════════════════════════════════════════════════════════════════════════
class _RailItem extends StatefulWidget {
  final NavigationItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 14 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white.withOpacity(0.18)
                : _hovered
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: widget.extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Indicador lateral
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: widget.selected ? 20 : 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: widget.selected ? 10 : (widget.extended ? 13 : 0)),
              Icon(
                widget.selected ? widget.item.activeIcon : widget.item.icon,
                color: widget.selected ? Colors.white : Colors.white.withOpacity(0.55),
                size: 22,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.selected ? Colors.white : Colors.white.withOpacity(0.55),
                      fontSize: 14,
                      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Botão de rodapé do rail (colapsar / sair)
// ═══════════════════════════════════════════════════════════════════════════════
class _RailFooterButton extends StatefulWidget {
  final bool extended;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _RailFooterButton({
    required this.extended,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_RailFooterButton> createState() => _RailFooterButtonState();
}

class _RailFooterButtonState extends State<_RailFooterButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDanger
        ? Colors.red[300]!
        : Colors.white.withOpacity(0.65);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 14 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDanger ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: color, size: 20),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item do Bottom Nav Flutuante
// ═══════════════════════════════════════════════════════════════════════════════
class _BottomNavItem extends StatefulWidget {
  final NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.selected ? 1.0 : 0.0,
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void didUpdateWidget(_BottomNavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone com pill de fundo animado
            ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(_scaleAnim),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.selected ? widget.item.activeIcon : widget.item.icon,
                  color: widget.selected ? Colors.white : Colors.white.withOpacity(0.45),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                color: widget.selected ? Colors.white : Colors.white.withOpacity(0.45),
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Modelo
// ═══════════════════════════════════════════════════════════════════════════════
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}