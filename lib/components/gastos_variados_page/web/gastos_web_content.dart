import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_resumo.dart';
import 'package:orcamentos_app/components/gastos_variados_page/web/gastos_web_sidebar.dart';
import 'package:orcamentos_app/components/gastos_variados_page/web/gastos_web_stats.dart';
import 'package:orcamentos_app/components/gastos_variados_page/web/gastos_web_table.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Corpo da versão web: cards + tabela à esquerda e painel lateral à direita.
class GastosWebContent extends StatelessWidget {
  /// Todos os gastos carregados (sem filtros), usados no card "Este mês".
  final List<GastoVariadoResponseDto> todos;
  final List<GastoVariadoResponseDto> filtrados;
  final List<CategoriaGastoResponseDto> categorias;
  final int? categoriaId;
  final DateTime? data;
  final ValueChanged<int?> onCategoria;
  final ValueChanged<DateTime?> onData;
  final VoidCallback onLimpar;
  final Future<void> Function(GastoVariadoResponseDto) onTapItem;

  const GastosWebContent({
    super.key,
    required this.todos,
    required this.filtrados,
    required this.categorias,
    required this.categoriaId,
    required this.data,
    required this.onCategoria,
    required this.onData,
    required this.onLimpar,
    required this.onTapItem,
  });

  /// Largura mínima disponível para exibir o painel lateral.
  static const double larguraMinimaSidebar = 1000;
  static const double _larguraSidebar = 300;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final resumo = GastosResumo.de(filtrados);
    final resumoMes = GastosResumo.de(todos
        .where((g) =>
            g.dataPgto.year == agora.year && g.dataPgto.month == agora.month)
        .toList());

    final principal = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: Column(
        children: [
          GastosWebStats(resumo: resumo, resumoMes: resumoMes),
          const SizedBox(height: 20),
          GastosWebTable(gastos: filtrados, onTapItem: onTapItem),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < larguraMinimaSidebar) return principal;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: principal),
          SizedBox(
            width: _larguraSidebar,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 28, 32),
              child: GastosWebSidebar(
                resumo: resumo,
                categorias: categorias,
                categoriaId: categoriaId,
                data: data,
                onCategoria: onCategoria,
                onData: onData,
                onLimpar: onLimpar,
              ),
            ),
          ),
        ],
      );
    });
  }
}
