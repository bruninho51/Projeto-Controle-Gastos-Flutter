import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_badge.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Card de categoria da versão web: ícone, nome, tipo e ações.
class CategoriesWebCard extends StatelessWidget {
  final CategoriaGastoResponseDto categoria;
  final Color color;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoriesWebCard({
    super.key,
    required this.categoria,
    required this.color,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  categoria.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kWebTexto,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              CategoryTipoBadge(tipo: categoria.tipo),
              const Spacer(),
              _Acao(
                tooltip: 'Editar categoria',
                icon: Icons.edit_outlined,
                cor: kIndigo,
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _Acao(
                tooltip: 'Excluir categoria',
                icon: Icons.delete_outline_rounded,
                cor: const Color(0xFFE53935),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color cor;
  final VoidCallback onTap;

  const _Acao({
    required this.tooltip,
    required this.icon,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cor),
        ),
      ),
    );
  }
}
