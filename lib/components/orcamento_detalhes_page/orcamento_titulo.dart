import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrcamentoTitulo extends StatelessWidget {
  final String nome;
  final bool isEncerrado;
  final String? dataEncerramento;
  final String? dataCriacao;
  final VoidCallback? onEditPressed;
  final VoidCallback? onEncerrarPressed;
  final VoidCallback? onApagarPressed;
  final VoidCallback? onReativarPressed;

  const OrcamentoTitulo({
    super.key,
    required this.nome,
    required this.isEncerrado,
    this.dataEncerramento,
    this.dataCriacao,
    this.onEditPressed,
    this.onEncerrarPressed,
    this.onApagarPressed,
    this.onReativarPressed,
  });

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return 'data inválida';
    }
  }

  void _showActionsMenu(BuildContext context, GlobalKey key) {
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: RelativeRect.fromLTRB(
        offset.dx - 160,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 200,
      ),
      items: [
        if (!isEncerrado && onEditPressed != null)
          _buildMenuItem(
            value: 'rename',
            icon: Icons.edit_outlined,
            label: 'Renomear',
            color: Colors.indigo[700]!,
          ),
        if (!isEncerrado && onEncerrarPressed != null)
          _buildMenuItem(
            value: 'encerrar',
            icon: Icons.lock_outline_rounded,
            label: 'Encerrar orçamento',
            color: const Color(0xFF546E7A),
          ),
        if (isEncerrado && onReativarPressed != null)
          _buildMenuItem(
            value: 'reativar',
            icon: Icons.lock_open_rounded,
            label: 'Reativar orçamento',
            color: const Color(0xFF43A047),
          ),
        if (onApagarPressed != null && !isEncerrado)
          _buildMenuItem(
            value: 'apagar',
            icon: Icons.delete_outline_rounded,
            label: 'Apagar orçamento',
            color: const Color(0xFFE53935),
            isDanger: true,
          ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'rename':
          onEditPressed?.call();
          break;
        case 'encerrar':
          onEncerrarPressed?.call();
          break;
        case 'reativar':
          onReativarPressed?.call();
          break;
        case 'apagar':
          onApagarPressed?.call();
          break;
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
    bool isDanger = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDanger ? color : const Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuKey = GlobalKey();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Ícone ────────────────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isEncerrado ? Colors.grey[100] : Colors.indigo[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: isEncerrado ? Colors.grey[400] : Colors.indigo[700],
              size: 24,
            ),
          ),

          // ── Nome + status ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Badge de status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEncerrado ? Colors.grey[100] : Colors.indigo[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isEncerrado ? Colors.grey[400] : Colors.indigo[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isEncerrado ? 'Encerrado' : 'Ativo',
                            style: TextStyle(
                              color: isEncerrado ? Colors.grey[600] : Colors.indigo[700],
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isEncerrado && dataEncerramento != null
                            ? 'Encerrado em ${_formatDate(dataEncerramento!)}'
                            : dataCriacao != null
                            ? 'Criado em ${_formatDate(dataCriacao!)}'
                            : '',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Botão de menu ─────────────────────────────────────────────────
          const SizedBox(width: 8),
          Material(
            key: menuKey,
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showActionsMenu(context, menuKey),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}