import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';

class SharedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData mainIcon;
  final List<Color> gradientColors;
  final List<_HeaderButton> actionButtons;
  final Widget? bottomContent;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showAvatar;

  const SharedAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mainIcon,
    required this.gradientColors,
    this.actionButtons = const [],
    this.bottomContent,
    this.showBackButton = false,
    this.onBack,
    this.showAvatar = true,
  });

  /// Única forma de criar botões aceitos por [actionButtons].
  ///
  /// ```dart
  /// actionButtons: [
  ///   SharedAppBar.headerButton(
  ///     child: const Icon(Icons.add, color: Colors.white),
  ///     onTap: () {},
  ///     tooltip: 'Adicionar',
  ///   ),
  /// ]
  /// ```
  static _HeaderButton headerButton({
    required Widget child,
    required VoidCallback onTap,
    required String tooltip,
    bool isSquare = false,
  }) {
    return _HeaderButton(
      child: child,
      onTap: onTap,
      tooltip: tooltip,
      isSquare: isSquare,
    );
  }

  @override
  State<SharedAppBar> createState() => _SharedAppBarState();

  @override
  Size get preferredSize {
    final hasBottom = bottomContent != null || actionButtons.isNotEmpty;
    final bottomHeight = hasBottom ? 44.0 : 0.0;
    return Size.fromHeight(kToolbarHeight + 35.0 + bottomHeight);
  }
}

class _SharedAppBarState extends State<SharedAppBar> {
  AuthState get _auth => Provider.of<AuthState>(context, listen: false);

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final photoURL = _auth.user?.photoURL;

    if (widget.showAvatar && photoURL != null) {
      return ClipOval(
        child: Image.network(
          photoURL,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _FallbackAvatar(),
        ),
      );
    }

    return const _FallbackAvatar();
  }

  // ── Linha superior ────────────────────────────────────────────────────────

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showBackButton && widget.onBack != null) ...[
          _HeaderButton(
            onTap: widget.onBack!,
            tooltip: 'Voltar',
            isSquare: true,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
        ],
        _AppBarIcon(icon: widget.mainIcon),
        const SizedBox(width: 12),
        Expanded(
          child: _AppBarTitles(
            title: widget.title,
            subtitle: widget.subtitle,
          ),
        ),
        const SizedBox(width: 10),
        if (widget.showAvatar) _buildAvatar(),
      ],
    );
  }

  // ── Linha inferior ────────────────────────────────────────────────────────

  Widget _buildBottomRow() {
    return Row(
      children: [
        if (widget.bottomContent != null)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.bottomContent!,
            ),
          ),
        const Spacer(),
        if (widget.actionButtons.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: widget.actionButtons,
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: _buildDecoration(),
      padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          if (widget.bottomContent != null || widget.actionButtons.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildBottomRow(),
          ],
        ],
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.gradientColors,
      ),
      boxShadow: [
        BoxShadow(
          color: widget.gradientColors[0].withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBarIcon
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarIcon extends StatelessWidget {
  final IconData icon;

  const _AppBarIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppBarTitles
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarTitles extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AppBarTitles({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FallbackAvatar
// ─────────────────────────────────────────────────────────────────────────────

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeaderButton
//
// Componente interno — acesse via SharedAppBar.headerButton(...)
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool isSquare;

  const _HeaderButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.isSquare = false,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) {
    setState(() => _pressed = false);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSquare ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}