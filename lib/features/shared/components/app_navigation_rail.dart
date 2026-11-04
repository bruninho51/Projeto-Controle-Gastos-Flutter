import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/navigation/app_navigation_items.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_item.dart';

class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final bool extended;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExtended;
  final VoidCallback onLogout;

  /// Índice do item exibido ao tocar no card do usuário (perfil).
  final int? profileIndex;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.extended,
    required this.onItemSelected,
    required this.onToggleExtended,
    required this.onLogout,
    this.profileIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: extended ? 220 : 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: EdgeInsets.fromLTRB(
              extended ? 20 : 16,
              MediaQuery.of(context).padding.top + 20,
              extended ? 20 : 16,
              24,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                  ),
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Minhas\nFinanças',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Itens de navegação
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: kNavigationItems.asMap().entries.map((e) {
                  return _RailItem(
                    item: e.value,
                    selected: e.key == currentIndex,
                    extended: extended,
                    onTap: () => onItemSelected(e.key),
                  );
                }).toList(),
              ),
            ),
          ),

          // Rodapé: colapsar + sair + usuário
          Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              0,
              10,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              children: [
                _RailFooterButton(
                  extended: extended,
                  icon: extended
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  label: 'Recolher',
                  onTap: onToggleExtended,
                ),
                const SizedBox(height: 4),
                _RailFooterButton(
                  extended: extended,
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  onTap: onLogout,
                  isDanger: true,
                ),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                _RailUserCard(
                  extended: extended,
                  onTap: profileIndex == null
                      ? null
                      : () => onItemSelected(profileIndex!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card do usuário ─────────────────────────────────────────────────────────

class _RailUserCard extends StatelessWidget {
  final bool extended;
  final VoidCallback? onTap;

  const _RailUserCard({required this.extended, this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthState>(context).user;
    final nome = user?.displayName ?? user?.email ?? 'Usuário';
    final foto = user?.photoURL;

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: foto != null ? NetworkImage(foto) : null,
      child: foto == null
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 18)
          : null,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment:
              extended ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            avatar,
            if (extended) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Item do Navigation Rail ─────────────────────────────────────────────────

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
                ? Colors.white.withValues(alpha: 0.16)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.selected ? widget.item.activeIcon : widget.item.icon,
                color: widget.selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
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

// ─── Botão de rodapé do rail ──────────────────────────────────────────────────

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
    final color =
        widget.isDanger ? Colors.red[300]! : Colors.white.withValues(alpha: 0.65);

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
                ? (widget.isDanger
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
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
