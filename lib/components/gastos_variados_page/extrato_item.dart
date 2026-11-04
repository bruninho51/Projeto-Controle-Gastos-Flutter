import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_variados_page/categoria_visual.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/shared/api_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Item individual do extrato
// ═══════════════════════════════════════════════════════════════════════════════
class ExtratoItem extends StatelessWidget {
  final GastoVariadoResponseDto gasto;
  final bool isLast;
  final VoidCallback onTap;

  const ExtratoItem({
    required this.gasto,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valor = double.tryParse(gasto.valor) ?? 0;
    final descricao = gasto.descricao;
    final categoriaNome = gasto.categoriaGasto.nome;
    final tipo = gasto.categoriaGasto.tipo;
    final isPatrimonio = tipo == TipoCategoriaGasto.patrimonio;
    final color = isPatrimonio ? tipo.color : corDaCategoria(categoriaNome);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
        splashColor: color.withOpacity(0.06),
        highlightColor: color.withOpacity(0.03),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Ícone da categoria
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconeDaCategoria(categoriaNome),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Descrição + categoria
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descricao,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoriaNome,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),

                  // Valor
                  Text(
                    isPatrimonio ? fmt.format(valor) : '- ${fmt.format(valor)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPatrimonio ? color : Colors.grey[800],
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Divisor (exceto no último)
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 70),
                child: Container(height: 1, color: Colors.grey[100]),
              ),
          ],
        ),
      ),
    );
  }
}
